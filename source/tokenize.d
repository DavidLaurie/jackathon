module tokenize;

import std.algorithm.comparison;

struct Token
{
    char[] token;
}

Token getToken(char[] source)
{
    Token token;
    int len;

    len = min(getNewlines(source), 255);
    if (len) {
        token.token = source[0..len];
        return token;
    }

    len = min(getWhitespace(source), 255);
    if (len) {
        token.token = source[0..len];
        return token;
    }

    len = min(getWord(source), 255);
    if (len) {
        token.token = source[0..len];
        return token;
    }

    len = min(getAnythingElse(source), 255);
    if (len) {
        token.token = source[0..len];
        return token;
    }

    throw new Exception("Bug in parsing");
}

int getNewlines(char[] source)
{
    int i;
    for (i = 0; i < source.length; i += 1)
    {
        if (source[i] != '\n' && source[i] != '\r')
        {
            break;
        }
    }
    return i;
}

int getWhitespace(char[] source)
{
    int i;
    for (i = 0; i < source.length; i += 1)
    {
        if (source[i] != ' ' && source[i] != '\t')
        {
            break;
        }
    }
    return i;
}

int getWord(char[] source)
{
    bool isLower = false;
    int i;

    for (i = 0; i < source.length; i += 1)
    {
        if (source[i] >= 'a' && source[i] <= 'z')
        {
            isLower = true;
            continue;
        }

        if (source[i] >= 'A' && source[i] <= 'Z')
        {
            // if (isLower)
            // {
            //     break;
            // }
            continue;
        }

        // Count unicode as word chars
        if ((source[i] & 0b11000000) == 0b10000000
            || (source[i] & 0b11100000) == 0b11000000
            || (source[i] & 0b11110000) == 0b11100000
            || (source[i] & 0b11111000) == 0b11110000
        ) {
            continue;
        }

        // Count ext ascii as word chars
        if (source[i] >= 0x80)
        {
            continue;
        }

        break;
    }
    return i;
}

int getAnythingElse(char[] source)
{
    int i;
    for (i = 0; i < source.length; i += 1)
    {
        char c = source[i];
        if (c == '\n' || c == '\r'
            ||c == ' ' ||c == '\t'
            || (c >= 'a' && c <= 'z')
            || (c >= 'A' && c <= 'Z')
        ) {
            break;
        }
    }
    return i;
}