module compression;

import std.stdio;
import std.file;
import std.conv;
import tokenize;
import bits;

void writeByte(File* f, char c)
{
    char[1] buffer = [ c ];
    f.rawWrite(buffer);
}

void writeLittleShort(File* f, ushort s)
{
    char[2] buffer = [
        s & 0xff,
        (s & 0xff00) >> 8,
    ];
    f.rawWrite(buffer);
}

void writeLittleInt(File* f, uint i)
{
    char[4] buffer = [
        i & 0xff,
        (i & 0xff00) >> 8,
        (i & 0xff0000) >> 16,
        (i & 0xff000000) >> 24,
    ];
    f.rawWrite(buffer);
}

void writeTokenList(File* f, Token[] tokens)
{
    foreach (Token token; tokens)
    {
        writeByte(f, cast(byte)token.token.length);
        f.rawWrite(token.token);
    }
}

void writeCompactedTokens(File* f, uint[] tokens, int bitSize)
{
    uint[] packed = bitPack(tokens, bitSize);

    if (bitSize >= 32)
    {
        throw new Exception("Bitsize must be less than 32");
    }

    writeLittleInt(f, cast(int)tokens.length);
    writeLittleInt(f, cast(int)packed.length);

    foreach (uint datum; packed)
    {
        writeLittleInt(f, datum);
    }
}

struct TokenData
{
    Token[] tokenList;
    uint[string] tokenIndex;
    uint[] tokens;

    private int tokenListLength = 0;

    this(char[] file, TokenParams params)
    {
        uint pos = 0;
        while (pos < file.length)
        {
            Token token = getToken(file[pos..$], params);
            auto ptr = (token.token in tokenIndex);
            if (ptr is null) {
                tokenList ~= token;
                tokenIndex[token.token.idup] = cast(uint)(tokenList.length - 1);
                tokens ~= cast(uint)(tokenList.length - 1);
                tokenListLength += token.token.length + 1;
            } else {
                tokens ~= *ptr;
            }
            pos += token.token.length;
        }
    }

    int getBitSize()
    {
        uint bitSize = 1;
        while ((1 << (bitSize - 1)) < tokenList.length)
        {
            bitSize += 1;
        }
        return bitSize;
    }

    int getFileSize()
    {
        return cast(int)(tokenListLength + (tokens.length * getBitSize()) / 8);
    }
}

TokenData getOptimalTokenData(char[] file)
{
    TokenParams[] paramSets = [
        TokenParams(4),
        TokenParams(6),
        TokenParams(8),
        TokenParams(10),
        TokenParams(12),
        TokenParams(14),
        TokenParams(16),
        TokenParams(20),
        TokenParams(24),
        TokenParams(28),
        TokenParams(32),
        TokenParams(36),
        TokenParams(40),
        TokenParams(48),
        TokenParams(64),
        TokenParams(64, true),
    ];

    TokenParams bestParam = TokenParams(2);
    TokenData best = TokenData(file, bestParam);
    int bestSize = best.getFileSize();
    foreach (TokenParams param; paramSets)
    {
        TokenData check = TokenData(file, param);
        if (check.getFileSize() <= bestSize)
        {
            best = check;
            bestSize = check.getFileSize();
            bestParam = param;
        }
    }

    writeln("Best parameterset was " ~ to!string(bestParam));

    return best;
}

int compress(string source, string dest)
{
    if (exists(dest))
    {
        writeln("Error: destination already exists");
        return 1;
    }

    writeln("Compressing " ~ source ~ " to " ~ dest);

    char[] file = cast(char[]) read(source);

    // 1. Tokenize file into tokens.
    //    Generate a list of unique tokens in the order they were found, and a list of the indexes of each token that was found.
    //TokenData tokenData = TokenData(file);
    TokenData tokenData = getOptimalTokenData(file);
    uint bitSize = tokenData.getBitSize();

    writeln(to!string(tokenData.tokenList.length) ~ " unique tokens");
    writeln(to!string(tokenData.tokens.length) ~ " tokens total");
    writeln("Bitsize " ~ to!string(bitSize));

    // 2. Output the number of unique tokens, and the bit length required to index any token.
    auto destFile = new File(dest, "wb");
    char[4] header = "DLCF";
    destFile.rawWrite(header);
    writeLittleInt(destFile, cast(uint) tokenData.tokenList.length);
    writeByte(destFile, cast(char) bitSize);

    // 3. Output the tokens as length-preceeded strings.
    writeTokenList(destFile, tokenData.tokenList);

    // 4. Output the indices as compressed binary.
    writeCompactedTokens(destFile, tokenData.tokens, bitSize);

    destFile.close();

    return 0;
}

int dumpTokens(string source, string dest)
{
    if (exists(dest))
    {
        writeln("Error: destination already exists");
        return 1;
    }

    char[] file = cast(char[]) read(source);

    TokenData tokenData = getOptimalTokenData(file);

    auto destFile = new File(dest, "w");
    for (int i = 0; i < tokenData.tokenList.length; i += 1)
    {
        destFile.writeln(to!string(i) ~ ", \"" ~ to!string(tokenData.tokenList[i].token) ~ "\"");
    }
    destFile.close();

    return 0;
}
