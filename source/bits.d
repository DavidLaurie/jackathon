module bits;

import std.stdio;
import filereadwrite;

struct BitWriter
{
    File* f;
    const int maxBits = 32;
    uint current = 0;
    int currentBits = 0;

    this(File* f)
    {
        this.f = f;
    }

    void write(uint data, int dataBits)
    {
        data &= (1 << dataBits) - 1;
        if (currentBits + dataBits >= maxBits)
        {
            current |= data << currentBits;
            writeLittleInt(f, current);

            current = data >> (maxBits - currentBits);
            currentBits = (dataBits + currentBits) - maxBits;
        }
        else
        {
            current |= data << currentBits;
            currentBits += dataBits;
        }
    }

    void flush()
    {
        if (currentBits)
        {
            writeLittleInt(f, current);
            current = 0;
            currentBits = 0;
        }
    }
}

uint[] bitPack(uint[] data, int dataBits)
{
    uint mask = (1 << dataBits) - 1;
    uint current;
    int currentBits = 0;
    int maxBits = 32;

    uint[] output;

    foreach (uint datum; data)
    {
        datum &= mask;
        if (currentBits + dataBits >= maxBits)
        {
            current |= datum << currentBits;
            output ~= current;

            current = datum >> (maxBits - currentBits);
            currentBits = (dataBits + currentBits) - maxBits;
        }
        else
        {
            current |= datum << currentBits;
            currentBits += dataBits;
        }
    }

    if (currentBits)
    {
        output ~= current;
    }

    return output;
}

struct BitReader
{
    File* f;
    int currentBits = 0;
    ulong current = 0;

    this(File* f)
    {
        this.f = f;
    }

    uint read(int dataBits)
    {
        if (currentBits < dataBits)
        {
            current |= (cast(ulong)readLittleInt(f)) << currentBits;
        }

        uint mask = (1 << dataBits) - 1;
        uint result = current & mask;
        current >>= dataBits;
        currentBits -= dataBits;
        return result;
    }
}

uint[] bitUnpack(uint[] data, uint expectedSize, int dataBits)
{
    uint mask = (1 << dataBits) - 1;
    int currentIndex = 0;
    int currentBits = 32;
    // 64 bits so we can pile more data in on top of existing bits
    ulong current = data[currentIndex];

    uint[] output;

    for (int i = 0; i < expectedSize; i += 1)
    {
        if (currentBits < dataBits)
        {
            currentIndex += 1;
            current |= (cast(ulong) data[currentIndex]) << currentBits;
            currentBits += 32;
        }

        output ~= current & mask;
        current >>= dataBits;
        currentBits -= dataBits;
    }

    return output;
}

unittest
{
    uint[] data = [
        0x000000a3,
        0x000000b5,
        0x000000c7,
        0x000000d9,
        0x000000ea,
    ];

    uint[] packed1 = bitPack(data, 8);
    assert(packed1.length == 2);
    assert(packed1[0] == 0xd9c7b5a3);
    assert(packed1[1] == 0x000000ea);

    uint[] packed2 = bitPack(data, 12);
    assert(packed2.length == 2);
    assert(packed2[0] == 0xc70b50a3);
    assert(packed2[1] == 0x00ea0d90);

    uint[] unpacked1 = bitUnpack(packed1, 5, 8);
    assert(unpacked1.length == 5);
    assert(unpacked1[0] == 0x000000a3);
    assert(unpacked1[1] == 0x000000b5);
    assert(unpacked1[2] == 0x000000c7);
    assert(unpacked1[3] == 0x000000d9);
    assert(unpacked1[4] == 0x000000ea);

    uint[] unpacked2 = bitUnpack(packed2, 5, 12);
    assert(unpacked2.length == 5);
    assert(unpacked2[0] == 0x000000a3);
    assert(unpacked2[1] == 0x000000b5);
    assert(unpacked2[2] == 0x000000c7);
    assert(unpacked2[3] == 0x000000d9);
    assert(unpacked2[4] == 0x000000ea);
}
