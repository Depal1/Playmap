```
OVERVIEW: Modify the layout of a Playmap file.

This command reads a Playmap file, modifies its layout according to the specified from and to layouts, and writes the modified content to the output Playmap.

USAGE: playmap layout <input-file> <output-file> <from-layout> <to-layout>

ARGUMENTS:
  <input-file>            Path to the input file.
  <output-file>           Path to the output file.
  <from-layout>           Current layout of the file: QWERTY, AZERTY, or QWERTZ.
  <to-layout>             Desired layout of the file: QWERTY, AZERTY, or QWERTZ.

OPTIONS:
  -h, --help              Show help information.
```

```
OVERVIEW: Fetch and handle files from a URL or local directory.

USAGE: playmap fetch [<bundle-id>] [--readme] [--download] [--source <source>]

ARGUMENTS:
  <bundle-id>             The bundle ID of the keymap.

OPTIONS:
  --readme                Fetch and print the README.md file if available.
  --download              Prompt to download a file.
  --source <source>       The name of the GitHub repository (USERNAME/REPOSITORY) or local path to repository.
  -h, --help              Show help information.
```