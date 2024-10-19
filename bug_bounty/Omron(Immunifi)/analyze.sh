slither . --include-paths='./OmronDeposit.sol' >> slither.log 2>&1
sed -i '' '1,3d' slither.log
