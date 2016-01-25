clc
clear 
close

load powertree_ml

goodleaf = zeros(length(dr12),1);
for nn = 1: length(dr12)
    if(rank(dr12(nn).xdata{1,1})==3)
       goodleaf(nn) = nn;
    end
end

goodleafidx = find(goodleaf~=0);    

yg = []; yf = [];
for nn = 1:length(goodleafidx)
    yg = [yg,dr12(goodleafidx(nn)).ydata{1,1}'];
    yf = [yf,dr12(goodleafidx(nn)).mdl.Fitted'];
end

res = (yf-yg)/1e3;
%stem(res);
residx = find((res<-90) | (res>90));
res(residx)=[];
stem(res/1e3);