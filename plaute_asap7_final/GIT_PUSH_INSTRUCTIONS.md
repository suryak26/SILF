# Push to SILF

The target repository is:

https://github.com/suryak26/SILF

Because the ChatGPT runtime cannot use your GitHub credentials or directly push to your authenticated Git repository, run the following from your WSL Ubuntu shell.

## 1. Clone or enter the repository

```bash
cd ~
git clone https://github.com/suryak26/SILF.git
cd SILF
```

If it is already cloned:

```bash
cd ~/SILF
git pull origin main
```

## 2. Copy this package

Extract this folder so that the result is:

```text
~/SILF/palute_7nm_final/
```

Then import the earlier successful ORFS run:

```bash
chmod +x palute_7nm_final/scripts/collect_existing_orfs_results.sh
./palute_7nm_final/scripts/collect_existing_orfs_results.sh
```

## 3. Inspect

```bash
git status
du -sh palute_7nm_final
find palute_7nm_final -maxdepth 3 -type f | sort
```

## 4. Commit

```bash
git add palute_7nm_final
git commit -m "Add PALUTE 7nm ASIC work package"
```

## 5. Push

```bash
git push origin main
```

Do not add the external PALUTE research paper unless its redistribution/license terms allow it.
