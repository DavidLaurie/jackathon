module compression;

import std.stdio;
import std.file;
import std.conv;
import tokenize;

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

void writeLittleInt(File* f, ulong i)
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
        writeLittleShort(f, cast(ushort)token.token.length);
        f.rawWrite(token.token);
    }
}

void writeCompactedTokens(File* f, ulong[] tokens, int bitSize)
{
    // TODO: We really want to squish this down with a blit type thing.

    if (bitSize != 16)
    {
        throw new Exception("Bitsize must be 16 at the moment");
    }

    writeLittleInt(f, tokens.length);

    foreach (ulong token; tokens)
    {
        writeLittleShort(f, cast(ushort)token);
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
    ulong[string] tokenIndex;
    ulong[] tokens;
    ulong pos = 0;
    while (pos < file.length)
    {
        Token token = getToken(file[pos..$]);
        auto ptr = (token.token in tokenIndex);
        if (ptr is null) {
            tokenList ~= token;
            tokenIndex[token.token.idup] = tokenList.length - 1;
            tokens ~= tokenList.length - 1;
        } else {
            tokens ~= *ptr;
        }
        pos += token.token.length;
    }

    writeln(to!string(tokenList.length) ~ " unique tokens");
    writeln(to!string(tokens.length) ~ " tokens total");
    int bitSize = 16; // TODO: Get this from the number of unique tokens.

    // 2. Output the number of unique tokens, and the bit length required to index any token.
    auto destFile = new File(dest, "wb");
    char[4] header = "DLCF";
    destFile.rawWrite(header);
    writeLittleInt(destFile, tokenList.length);
    writeByte(destFile, cast(char) bitSize); // Quick hack - just use 16 bits

    // 3. Output the tokens as length-preceeded strings.
    writeTokenList(destFile, tokenList);

    // 4. Output the indices as compressed binary.
    writeCompactedTokens(destFile, tokens, bitSize);

    destFile.close();

    return 0;
}
