clear
price = readtable("prices.csv");
%%
%price=price(find(ismember(price.TSYMBOL,{'AAPL'})),:);
price=price(1:end,["DATE","sprtrn"]);
price=table2array(price);
price = price((price(:,1)>20060102),:);
%%
[date_unique,id,~]=unique(price(:,1),'sorted');
sprtrn=price(id,2);
price_unique=[date_unique,sprtrn];
spy_price = zeros(length(price_unique(:,1)),1);
%%
spy_price(1)=1268.8;
for j = 2:length(price_unique(:,1))
    spy_price(j)=spy_price(j-1)*(sprtrn(j)+1);
    disp(j)
end
SPY=[price_unique,spy_price];

writematrix(SPY,'spy_price.xlsx');