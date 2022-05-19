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
    Token[] tokenList;
    uint[string] tokenIndex;
    uint[] tokens;
    uint pos = 0;
    while (pos < file.length)
    {
        Token token = getToken(file[pos..$]);
        auto ptr = (token.token in tokenIndex);
        if (ptr is null) {
            tokenList ~= token;
            tokenIndex[token.token.idup] = cast(uint)(tokenList.length - 1);
            tokens ~= cast(uint)(tokenList.length - 1);
        } else {
            tokens ~= *ptr;
        }
        pos += token.token.length;
    }

    writeln(to!string(tokenList.length) ~ " unique tokens");
    writeln(to!string(tokens.length) ~ " tokens total");
    uint bitSize = 1;
    while ((1 << (bitSize - 1)) < tokenList.length)
    {
        bitSize += 1;
    }
    writeln("Bitsize " ~ to!string(bitSize));

    // 2. Output the number of unique tokens, and the bit length required to index any token.
    auto destFile = new File(dest, "wb");
    char[4] header = "DLCF";
    destFile.rawWrite(header);
    writeLittleInt(destFile, cast(uint) tokenList.length);
    writeByte(destFile, cast(char) bitSize);

    // 3. Output the tokens as length-preceeded strings.
    writeTokenList(destFile, tokenList);

    // 4. Output the indices as compressed binary.
    writeCompactedTokens(destFile, tokens, bitSize);

    destFile.close();

    return 0;
}
