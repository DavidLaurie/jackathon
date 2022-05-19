module decompression;

import std.stdio;
import std.file;
import std.conv;

alias ReadToken = char[];

char readByte(File* f)
{
    char[1] buf;
    f.rawRead(buf);
    return buf[0];
}

ushort readLittleShort(File *f)
{
    char[2] buf;
    f.rawRead(buf);
    return buf[0] + (buf[1] << 8);
}

ulong readLittleInt(File* f)
{
    char[4] buf;
    f.rawRead(buf);
    return buf[0] + (buf[1] << 8) + (buf[2] << 16) + (buf[3] << 24);
}

ReadToken readToken(File* f)
{
    ushort length = readLittleShort(f);
    ReadToken token;
    token.length = length;
    f.rawRead(token);
    return token;
}

ulong[] readTokens(File* f, int numTokens, int bitSize)
{
    if (bitSize != 16)
    {
        throw new Exception("Bitsize must be 16 at the moment");
    }

    ulong[] tokens;
    for (int i = 0; i < numTokens; i += 1)
    {
        tokens ~= readLittleShort(f);
    }

    return tokens;
}

int decompress(string source, string dest)
{
    if (exists(dest))
    {
        writeln("Error: destination already exists");
        return 1;
    }

    writeln("Decompressing " ~ source ~ " to " ~ dest);

    auto input = new File(source, "rb");

    // 1. Expect 'DLCF', read token list length and bitsize.
    char[4] header;
    input.rawRead(header);
    if (header != "DLCF")
    {
        writeln("Expected DLCF header, got " ~ header);
        return 1;
    }

    int numTokenList = cast(int) readLittleInt(input);
    int bitSize = cast(int) readByte(input);

    writeln(to!string(numTokenList) ~ " unique tokens");
    writeln("Bitsize " ~ to!string(bitSize));

    // 2. Allocate token list and read the strings.
    ReadToken[] tokenList;
    for (auto i = 0; i < numTokenList; i += 1)
    {
        tokenList ~= readToken(input);
    }

    // 3. Read the remainder of the file and uncompact it to a token list.
    int numTokens = cast(int) readLittleInt(input);
    writeln(to!string(numTokens) ~ " tokens");
    ulong[] tokens = readTokens(input, numTokens, bitSize);

    // 4. Write all the tokens.
    auto destFile = new File(dest, "wb");
    foreach (ulong token; tokens)
    {
        destFile.rawWrite(tokenList[token]);
    }

    return 0;
}
