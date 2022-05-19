import std.stdio;
import compression;
import decompression;

int usage(int code = 0)
{
    writeln("jackathon <mode> <input> <output>");
    writeln("  <mode> must be 'compress' or 'decompress'");
    writeln("  <input> is the input filename");
    writeln("  <output> is the output filename");
    return code;
}

int main(string[] argv)
{
    if (argv.length < 4)
    {
        return usage();
    }

    if (argv[1] == "compress")
    {
        return compress(argv[2], argv[3]);
    }
    else if (argv[1] == "decompress")
    {
        return decompress(argv[2], argv[3]);
    }
    else if (argv[1] == "dump-tokens")
    {
        return dumpTokens(argv[2], argv[3]);
    }
    else
    {
        writeln("Invalid mode");
        return usage(1);
    }
}
