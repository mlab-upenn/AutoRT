function yopt = mbCRTOpt(tree, TermNodeVals, linregCoeff, TestInput)

treeOutput = predict(tree, TestInput);
nodeIdx = find(TermNodeVals == treeOutput);
B = linregCoeff{nodeIdx}; %#ok<FNDSB>
f = [0,0,0,1];
y = linprog(f, [], [], [B(2:end) -1], -B(1));
yopt = y(4);