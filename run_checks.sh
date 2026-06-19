#!/bin/bash
set -u
cd /home/runner/work/ettbc/ettbc

echo "=== COMMAND 1: devtools::load_all() ==="
Rscript -e "devtools::load_all()"
echo "EXIT_CODE_1=$?"

echo ""
echo "=== COMMAND 2: lintr::lint_package() ==="
Rscript -e "lintr::lint_package()"
echo "EXIT_CODE_2=$?"

echo ""
echo "=== COMMAND 3: spelling::spell_check_package() ==="
Rscript -e "spelling::spell_check_package()"
echo "EXIT_CODE_3=$?"

echo ""
echo "=== COMMAND 4: devtools::test() ==="
Rscript -e "devtools::test()"
echo "EXIT_CODE_4=$?"
