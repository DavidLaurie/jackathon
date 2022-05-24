module tokenindex;

import tokenize;

struct IndexItem
{
    int count;
    char[] value;
}

struct DataItem
{
    // Value is used if index is 0
    int index;
    char[] value;
}

struct TokenIndex
{

    IndexItem[] index;
    DataItem[] data;

    private uint tokenIndexSize = 0;

    this(char[] file, TokenParams params)
    {
        ParseToken[] tokenList;
        uint[char[]] tokenLookup;
        uint[] tokenData;

        // Build an inefficient list of all the tokens and their counts.
        uint pos = 0;
        while (pos < file.length)
        {
            ParseToken token = getToken(file[pos..$], params);
            auto ptr = (token.token in tokenLookup);
            if (ptr is null) {
                token.count = 1;
                tokenLookup[token.token.idup] = cast(uint)tokenList.length;
                tokenData ~= cast(uint)tokenList.length;
                tokenList ~= token;
                tokenIndexSize += token.token.length + 1;
            } else {
                tokenList[*ptr].count += 1;
                tokenData ~= *ptr;
            }
            pos += token.token.length;
        }

        // Put only tokens of length greater than 1 into the index, and build a map.
        uint[] tokenListToIndex;
        index ~= IndexItem(0);
        for (int i = 0; i < tokenList.length; i += 1)
        {
            if (tokenList[i].count > 1)
            {
                tokenListToIndex ~= cast(uint)index.length;
                index ~= IndexItem(tokenList[i].count, tokenList[i].token);
            }
            else
            {
                tokenListToIndex ~= 0;
            }
        }

        // Build the data.
        for (int i = 0; i < tokenData.length; i += 1)
        {
            uint realIndex = tokenListToIndex[tokenData[i]];
            if (realIndex == 0)
            {
                data ~= DataItem(0, tokenList[tokenData[i]].token);
            }
            else
            {
                data ~= DataItem(realIndex);
            }
        }
    }

    int getBitSize()
    {
        uint bitSize = 1;
        while ((1 << (bitSize - 1)) < index.length)
        {
            bitSize += 1;
        }
        return bitSize;
    }

    int getFileSize()
    {
        return cast(int)(tokenIndexSize + (data.length * getBitSize()) / 8);
    }
}
