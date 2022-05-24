module compression;

import std.stdio;
import std.file;
import std.conv;
import tokenize;
import tokenindex;
import filereadwrite;
import bits;

void writeTokenList(File* f, IndexItem[] items)
{
    foreach (IndexItem item; items)
    {
        writeByte(f, cast(byte)item.value.length);
        f.rawWrite(item.value);
    }
}

void writeCompactedTokens(File* f, DataItem[] data, int bitSize)
{
    if (bitSize >= 32)
    {
        throw new Exception("Bitsize must be less than 32");
    }

    writeLittleInt(f, cast(uint)data.length);
    BitWriter writer = BitWriter(f);

    foreach (DataItem item; data)
    {
        writer.write(item.index, bitSize);
        if (item.index == 0)
        {
            writer.write(cast(uint)item.value.length, 8);
            foreach (char c; item.value)
            {
                writer.write(c, 8);
            }
        }
    }
    writer.flush();
}

TokenIndex getOptimalTokenIndex(char[] file)
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
    TokenIndex best = TokenIndex(file, bestParam);
    int bestSize = best.getFileSize();
    foreach (TokenParams param; paramSets)
    {
        TokenIndex check = TokenIndex(file, param);
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
    TokenIndex tokenIndex = getOptimalTokenIndex(file);
    uint bitSize = tokenIndex.getBitSize();

    writeln(to!string(tokenIndex.index.length) ~ " unique tokens");
    writeln(to!string(tokenIndex.data.length) ~ " tokens total");
    writeln("Bitsize " ~ to!string(bitSize));

    // 2. Output the number of unique tokens, and the bit length required to index any token.
    auto destFile = new File(dest, "wb");
    char[4] header = "DLCF";
    destFile.rawWrite(header);
    writeLittleInt(destFile, cast(uint) tokenIndex.index.length - 1);
    writeByte(destFile, cast(char) bitSize);

    // 3. Output the tokens as length-preceeded strings.
    writeTokenList(destFile, tokenIndex.index[1..$]);

    // 4. Output the indices as compressed binary.
    writeCompactedTokens(destFile, tokenIndex.data, bitSize);

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

    TokenIndex tokenIndex = getOptimalTokenIndex(file);

    auto destFile = new File(dest, "w");
    for (int i = 0; i < tokenIndex.index.length; i += 1)
    {
        destFile.writeln(to!string(i) ~ ", \"" ~ to!string(tokenIndex.index[i].count) ~ ", " ~ to!string(tokenIndex.index[i].value) ~ "\"");
    }

    destFile.close();
    return 0;
}
