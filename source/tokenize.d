module tokenize;

import std.algorithm.comparison;
import charstuff;

struct TokenParams
{
    byte maxTokenLength;
    bool quotedWords;
}

struct Token
{
    char[] token;
}

Token getToken(char[] source, TokenParams params = TokenParams(64))
{
    int maxTokenLength = params.maxTokenLength;
    if (maxTokenLength == 0)
    {
        maxTokenLength = 256;
    }

    Token token;
    int len;

    len = min(getNewlines(source), maxTokenLength);
    if (len) {
        token.token = source[0..len];
        return token;
    }

    len = min(getWhitespace(source), maxTokenLength);
    if (len) {
        token.token = source[0..len];
        return token;
    }

    len = min(getWord(source, params.quotedWords), maxTokenLength);
    if (len) {
        token.token = source[0..len];
        return token;
    }

    len = min(getAnythingElse(source), maxTokenLength);
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

int getWord(char[] source, bool quoted)
{
    int i;
    for (i = 0; i < source.length; i += 1)
    {
        if (isWordChar(source[i]))
        {
            continue;
        }
        if (quoted && source[i] == '"')
        {
            continue;
        }
        break;
    }
    return i;
}

int getNumber(char[] source)
{
    int i;
    for (i = 0; i < source.length; i += 1)
    {
        if (isDigit(source[i]) || (i == 0 && source[i] == '-') || (i > 0 && source[i] == '.'))
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
        if (isWordChar(c) || isNewline(c) || isNonNewlineWhitespace(c)) {
            break;
        }
    }
    return i;
}