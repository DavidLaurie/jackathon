<?php

function getTempFileName(): string
{
    $filename = tempnam(sys_get_temp_dir(), 'david');
    unlink($filename);
    return $filename;
}

function compress(string $input): string
{
    $inFile = getTempFileName();
    $outFile = getTempFileName();

    file_put_contents($inFile, $input);
    print shell_exec("./jackathon compress {$inFile} {$outFile}");

    return file_get_contents($outFile);
}

function decompress(string $input): string
{
    $inFile = getTempFileName();
    $outFile = getTempFileName();

    file_put_contents($inFile, $input);
    print shell_exec("./jackathon decompress {$inFile} {$outFile}");

    return file_get_contents($outFile);
}

function test(): void
{
    $files = scandir('fixtures');
    $ratios = [];

    foreach ($files as $file) {
        if (!preg_match('/\.(css|json|txt)$/', $file)) {
            continue;
        }

        $input = file_get_contents('fixtures/' . $file);

        $compressed = compress($input);
        $decompressed = decompress($compressed);

        if ($decompressed !== $input) {
            echo "FAIL: Outputs do not match!\n";
        }

        $ratio = (1 - (mb_strlen($compressed) / mb_strlen($input))) * 100;
        $ratios[$file] = $ratio;
        echo 'File: ' . $file . ', Ratio: ' . round($ratio) . "%\n";

        print "---------------------------------------\n";
    }

    $ratioAverage = array_reduce($ratios, fn ($carry, $ratio) => $carry + $ratio) / count($ratios);

    echo 'Average Compression Ratio: ' . round($ratioAverage, 2) . "%\n";
}

test();
