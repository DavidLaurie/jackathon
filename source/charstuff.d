module charstuff;

bool isNewline(char c)
{
    return c == '\n' || c == '\r';
}

bool isNonNewlineWhitespace(char c)
{
    return c == ' ' || c == '\t';
}

bool isAlpha(char c)
{
    return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z');
}

bool isUnicode(char c)
{
    return (c & 0b11000000) == 0b10000000
        || (c & 0b11100000) == 0b11000000
        || (c & 0b11110000) == 0b11100000
        || (c & 0b11111000) == 0b11110000;
}

bool isExtAscii(char c)
{
    return c >= 0x80;
}

bool isWordChar(char c)
{
    return isAlpha(c) || isUnicode(c) || isExtAscii(c);
}

bool isDigit(char c)
{
    return 'c' >= '0' && c <= '9';
}