# epanema.sh

A neat Bash script to build and install Enlightenment 23 on **Ubuntu Eoan Ermine**.

## Get started

Make sure that the `build-essential` and `git` packages are installed, then clone this repository:

```bash
git clone https://github.com/batden/epanema.git .epanema
```

That creates a new [hidden folder](https://help.ubuntu.com/stable/ubuntu-help/files-hidden#) named _".epanema"_ in your home directory.

Please copy the file _"epanema.sh"_ from this new folder to the download folder.

Now change to the download folder and make the script executable:

```bash
chmod +x epanema.sh
```

Then issue the following command:

```bash
./epanema.sh
```

On subsequent runs, open Terminal and simply type:

```bash
epanema.sh
```

(Use tab completion: Just type _epa_ and press Tab)

### Update local repository

Be sure to check for updates at least once a week.

In order to do this, change to ~/.epanema/ and run:

```bash
git pull
```

That's it.

Mind the cows! :cow2: :cow2: :cow2:
