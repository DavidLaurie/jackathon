module filereadwrite;

import std.file;
import std.stdio;

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

void writeLittleInt(File* f, uint i)
{
    char[4] buffer = [
        i & 0xff,
        (i & 0xff00) >> 8,
        (i & 0xff0000) >> 16,
        (i & 0xff000000) >> 24,
    ];
    f.rawWrite(buffer);
}

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

uint readLittleInt(File* f)
{
    char[4] buf;
    f.rawRead(buf);
    return buf[0] + (buf[1] << 8) + (buf[2] << 16) + (buf[3] << 24);
}
