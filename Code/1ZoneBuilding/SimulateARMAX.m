% model:                an idpoly object
% TestingInput:         mxn matrix
% TestingOutput:        mx1 vector
% OutputData:           mx1 vector

function OutputData = SimulateARMAX(model, TestingInput, TestingOutput)

% A(z)y(t) = B(z)u(t) + e(t)
A = model.A;
B = model.B;

na = model.na;
nb = max(model.nb);

NoOfSamples = size(TestingInput,1);

if iscell(B)
    NoOfInputs = length(B);
else
    NoOfInputs = 1;
end

NoiseStd = 0*sqrt(model.NoiseVariance);
OutputData = zeros(NoOfSamples,1);

% Initialization: copy from TestingOutput
maxOrder = max(na, nb);
OutputData(1:maxOrder,1) = TestingOutput(1:maxOrder,1);

for idx = maxOrder+1:NoOfSamples
    
    b = 0;
    if NoOfInputs>1
        for idi = 1:NoOfInputs
            b = b + fliplr(B{idi})*TestingInput(idx-nb+1:idx,idi);
        end
    else
        b = fliplr(B)*TestingInput(idx-nb+1:idx,1);
    end
    
    OutputData(idx,1) = 1/A(1)*(-fliplr(A(2:end))*OutputData(idx-na:idx-1,1) + b + NoiseStd*randn);
    
end
