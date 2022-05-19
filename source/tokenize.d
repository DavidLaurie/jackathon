module tokenize;

struct Token
{
    char[] token;
}

Token getToken(char[] source)
{
    Token token;
    int len;

    len = getNewlines(source);
    if (len) {
        token.token = source[0..len];
        return token;
    }

    len = getWhitespace(source);
    if (len) {
        token.token = source[0..len];
        return token;
    }

    len = getWord(source);
    if (len) {
        token.token = source[0..len];
        return token;
    }

    len = getAnythingElse(source);
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