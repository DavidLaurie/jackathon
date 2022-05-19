module tokenize;

import std.algorithm.comparison;
import charstuff;

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
        if (!isNewline(source[i]))
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
        if (!isNonNewlineWhitespace(source[i]))
        {
            break;
        }
    }
    return i;
}

int getWord(char[] source)
{
    int i;

    for (i = 0; i < source.length; i += 1)
    {
        if (isWordChar(source[i]))
        {
            continue;
        }

        // Allow one space after a 1 or 2 letter word to join with another word
        // if (i > 1 && i < 4 && source[i] == ' ' && i < source.length - 1 && isWordChar(source[i+1]))
        // {
        //     continue;
        // }

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
        if (isWordChar(c) || isNewline(c) || isNonNewlineWhitespace(c)) {
            break;
        }
    }
    return i;
}