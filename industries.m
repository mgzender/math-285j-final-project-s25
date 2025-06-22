%This script uses proposal support to forecast returns by industry
clear
prices = readtable('prices.csv');
votes=readtable('votes.csv');
spy_price=readmatrix('spy_price.xlsx');
%%
text_p=prices.TSYMBOL;
[uniqueTickerv]=unique(votes.Ticker,'sort');
ids=votes.TickerID;
ticker_id=zeros(length(uniqueTickerv),1);
price_id=zeros(height(prices),1);
for j=1:length(uniqueTickerv)
    text_idx=find(ismember(votes.Ticker,uniqueTickerv(j)),1);
    price_tick_index=find(ismember(text_p,uniqueTickerv(j)));
    price_id(price_tick_index)=ids(text_idx);
end
prices.TickerID=price_id;
prices=prices(prices.TickerID~=0,:);
%%
sector = string(prices.SICCD);
%sector = extractBefore(sector,3);
sector=double(sector);
prices.Sector=sector;
prices.Sector(ismember(prices.TSYMBOL,{'A'}))=3826;
%%
votes_mat_full=votes(1:end,["TickerID","Year","DATE","CategoryCode","VoteFor","VoteAgainst"]);
votes_mat_full=table2array(votes_mat_full);
prices_mat_full=prices(1:end,["TickerID","year","DATE","OPENPRC", "Sector"]);
prices_mat_full=table2array(prices_mat_full);
%%
%pick specific category
category_code = 1:5;
category_vec=find(ismember(votes_mat_full(:,4),category_code));
votes_mat_full=votes_mat_full(category_vec,:);
%%
votes_current_year=votes_mat_full((votes_mat_full(:,2)==2024),:);
votes_prev_year=votes_mat_full((votes_mat_full(:,2)==2023),:);
prop_current=length(votes_current_year(:,1));

%%
%unique tickers and ids for the proposal type
ticker_full=unique(votes_current_year(:,1),'sort');
%%
%Adjacency matrix
A=zeros(length(ticker_full));
%%
    m_idx=zeros(1,length(ticker_full));
    for m = 1:length(ticker_full)
        prices_ticker_a = prices_mat_full(prices_mat_full(:,1)==ticker_full(m),:);
        max_date = max(prices_ticker_a(:,2));
        max_date_ind=find(prices_ticker_a(:,2)==max_date,1);
        m_idx(m)= prices_ticker_a(max_date_ind,5);
    end
    for n = 1:length(ticker_full)
        sector_vec= find(ismember(m_idx,m_idx(n)));
        A(n,sector_vec)=1;
        A(n,n)=0;
    end

%%
%take out zeros
zero_ind=find(~sum(A,2));
A(zero_ind,:)=[];
A(:,zero_ind)=[];
ticker_full(zero_ind)=[];
%%
percent_recent24=zeros(length(ticker_full),1);
return_recent24=zeros(length(ticker_full),1);
percent_recent23=zeros(length(ticker_full),1);
return_recent23=zeros(length(ticker_full),1);
recent_date24=zeros(length(ticker_full),1);
recent_date23=zeros(length(ticker_full),1);
num_proposals = zeros(length(ticker_full),1);
for i=1:length(ticker_full)
    votes_ticker24=votes_current_year(find(votes_current_year(:,1)==ticker_full(i)),:);
    num_proposals(i)=length(votes_ticker24(:,1));
    votes_ticker23=votes_prev_year(find(votes_prev_year(:,1)==ticker_full(i)),:);
    prices_ticker24=prices_mat_full(find(prices_mat_full(:,1)==ticker_full(i)),:);
    recent_date24(i)=votes_ticker24(1,3);
    percent_recent24(i)=mean(votes_ticker24(:,6));
    return_recent24(i)=open2open(prices_ticker24,recent_date24(i),spy_price,10);
    if ~isempty(votes_ticker23)
        recent_date23(i)=votes_ticker23(1,3);
        percent_recent23(i)=mean(votes_ticker23(:,6));
        return_recent23(i)=open2open(prices_ticker24,recent_date23(i),spy_price,10);
    end
end
%%
A_mat=A;
beta=zeros(length(ticker_full),1);
alpha=zeros(length(ticker_full),1);
for p = 1:length(ticker_full)
    percent_given= zeros(length(ticker_full),1);
    return_given= zeros(length(ticker_full),1);
    for k = 1:length(ticker_full)
        if  recent_date24(k)<recent_date24(p)
            percent_given(k)=percent_recent24(k);
            return_given(k)=return_recent24(k);
        elseif k~=p && recent_date23(k)>0
            percent_given(k)=percent_recent23(k);
            return_given(k)=return_recent23(k);
        end
    end
    x_tilde =A_mat(p,:).*percent_given';
    x_bar=mean(x_tilde)*ones(length(ticker_full),1);
    y_tilde = A_mat(p,:).*return_given';
    y_bar=mean(y_tilde)*ones(length(ticker_full),1);
    beta(p)= sum((x_tilde-x_bar).*(y_tilde-y_bar))/sum((x_tilde-x_bar).^2);
    alpha(p)= y_bar(1)-beta(p)*x_bar(1);
end
y_guess=alpha+beta.*percent_recent24;
actual_returns=return_recent24;
%%
PnL = sum(sign(y_guess).*actual_returns)*ones(length(ticker_full),1);
disp(PnL);
%%
ticker_text = unique(votes.Ticker(find(ismember(votes.TickerID,ticker_full))));
final_table = table(ticker_text,y_guess,actual_returns,PnL,'VariableNames',{'Company','Expected Return', 'Return', 'PnL'});
