module decompression;

import std.stdio;
import std.file;
import std.conv;
import bits;
import filereadwrite;

alias ReadToken = char[];

struct ReadTokenData
{
    int index;
    char[] value;
}

ReadToken readToken(File* f)
{
    uint length = cast(uint)readByte(f);
    if (length == 0)
    {
        length = 256;
    }

    ReadToken token;
    token.length = length;
    f.rawRead(token);
    return token;
}

ReadTokenData[] readTokens(File* f, int bitSize)
{
    int numTokens = cast(uint) readLittleInt(f);
    writeln(to!string(numTokens) ~ " tokens");

    if (bitSize >= 32)
    {
        throw new Exception("Bitsize must be less than 32");
    }

    BitReader reader = BitReader(f);
    ReadTokenData[] data;
    for (int i = 0; i < numTokens; i += 1)
    {
        ReadTokenData item;
        item.index = reader.read(bitSize);
        if (item.index == 0)
        {
            int count = reader.read(8);
            for (int j = 0; j < count; j += 1)
            {
                item.value ~= reader.read(8);
            }
        }
        data ~= item;
    }
    return data;
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
    char[] nullToken;
    tokenList ~= nullToken;
    for (auto i = 0; i < numTokenList; i += 1)
    {
        tokenList ~= readToken(input);
    }

    // 3. Read the remainder of the file and uncompact it to a token list.
    ReadTokenData[] data = readTokens(input, bitSize);

    // 4. Write all the tokens.
    auto destFile = new File(dest, "wb");
    foreach (ReadTokenData item; data)
    {
        if (item.index == 0)
        {
            destFile.rawWrite(item.value);
        }
        else
        {
            destFile.rawWrite(tokenList[item.index]);
        }
    }

    return 0;
}
