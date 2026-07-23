# Miscellaneous tools

This folder contains optional utilities that are useful when running STAR.

## Restart all providers

The restart tools discover every provider with an existing `.ini` configuration.
They also attempt to retain providers already running from the same STAR checkout.
Each provider reconnects to the server addresses already saved in its own
configuration; the tools never add or assume a public server address. Each
provider should normally use matching filenames, such as `example.py` and
`example.ini`.

### Windows

Double-click `Restart STAR Providers.cmd`. It launches the PowerShell helper in
this folder, restarts the discovered providers in hidden windows, and writes
`provider.log` and `provider-error.log` beside each provider.

### Linux

First make the script executable:

```bash
chmod +x misc/restart-star-providers.sh
```

Then run it from anywhere inside or outside the repository:

```bash
./misc/restart-star-providers.sh
```

It uses `python3` by default. To use a virtual environment or another Python
command, activate that environment first or set `PYTHON_COMMAND`, for example:

```bash
PYTHON_COMMAND=/path/to/venv/bin/python ./misc/restart-star-providers.sh
```

The Windows utility has been tested. The Linux utility should be tested on an
actual Linux STAR installation before a pull request is submitted.
