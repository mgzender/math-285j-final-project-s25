clear
prices = readtable('prices.csv');
votes=readtable('votes.csv');
%%
spy_price=readmatrix('spy_price.xlsx');
%%
price_year=prices.year;
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
%%
votes_mat_full=votes(1:end,["TickerID","Year","DATE","CategoryCode","VoteFor","VoteAgainst"]);
votes_mat_full=table2array(votes_mat_full);
prices_mat_full=prices(1:end,["TickerID","year","DATE","OPENPRC"]);
prices_mat_full=table2array(prices_mat_full);

%%
%pick specific category
category_code =1:5;
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
    year_vec = 2020:2022;
    %tiledlayout(2,5)
    for i = 1:length(year_vec)
        cluster1=[];
        cluster2=[];
        cluster3=[];
        cluster4=[];
        cluster5=[];
        cluster6=[];
        disp(i);
        year_vec_vote=find(ismember(votes_mat_full(:,2),year_vec(i)));
        year_vec_price=find(ismember(prices_mat_full(:,2),year_vec(i)));
        votes_mat_year=votes_mat_full(year_vec_vote,:);
        v_min=min(votes_mat_year(:,5));
        v_max=max(votes_mat_year(:,5));
        prices_mat_year=prices_mat_full(year_vec_price,:);
      
        ticker=unique(votes_mat_year(:,1),'sorted');
        h=length(ticker);

        cluster_mat = zeros(h,3);
        cluster_mat(:,1)=ticker;

        for j = 1:h
            k = find(prices_mat_year(:,1)==ticker(j));
            prices_mat_ticker=prices_mat_year(k,:);
            current_percent=mean(votes_mat_year(j,5));
            j_date=votes_mat_year(j,3);
            %open to open
            returns=open2open(prices_mat_ticker,j_date,spy_price,1);
            cluster_mat(j,2)=current_percent;
            cluster_mat(j,3)=returns;
        end
        %range of returns
        p_min=min(cluster_mat(:,3));
        p_max=max(cluster_mat(:,3));
        p_dec_med = median(cluster_mat((cluster_mat(:,3)<=0),3));
        p_inc_med = median(cluster_mat((cluster_mat(:,3)>0),3));
        price_range=[p_min,p_dec_med,0,p_inc_med,p_max];
        
        %Find price category
        p_inc_hi=find(cluster_mat(:,3)>price_range(4));
        p_inc_lo=find(cluster_mat(:,3)<=price_range(4)&cluster_mat(:,3)>0);
        p_dec_hi=find(cluster_mat(:,3)>price_range(2)&cluster_mat(:,3)<=0);
        p_dec_hi=find(cluster_mat(:,3)<=price_range(2));
        
        %range of support
        v_fail_med = median(cluster_mat((cluster_mat(:,2)<=0.5),2));
        v_pass_med = median(cluster_mat((cluster_mat(:,2)>0.5),2));
        vote_range=[v_min,v_fail_med,0.5,v_pass_med,v_max];

        %Find vote category
        v_pass_hi=find(cluster_mat(:,2)>vote_range(4));
        v_pass_lo=find(cluster_mat(:,2)<=vote_range(4)&cluster_mat(:,2)>0.5);
        v_fail_lo=find(cluster_mat(:,2)>vote_range(2)&cluster_mat(:,2)<=0.5);
        v_fail_hi=find(cluster_mat(:,2)<=vote_range(2));

        %find return & vote category
        inc_hi_pass_hi=v_pass_hi(find(ismember(v_pass_hi,p_inc_hi)));
        inc_hi_pass_lo=v_pass_lo(find(ismember(v_pass_lo,p_inc_hi)));
        inc_lo_pass_hi=v_pass_hi(find(ismember(v_pass_hi,p_inc_lo)));
        inc_lo_pass_lo=v_pass_lo(find(ismember(v_pass_lo,p_inc_lo)));
        dec_hi_pass_hi=v_pass_hi(find(ismember(v_pass_hi,p_dec_hi)));
        dec_hi_pass_lo=v_pass_lo(find(ismember(v_pass_lo,p_dec_hi)));
        dec_lo_pass_hi=v_pass_hi(find(ismember(v_pass_hi,p_dec_hi)));
        dec_lo_pass_lo=v_pass_lo(find(ismember(v_pass_lo,p_dec_hi)));

        inc_hi_fail_hi=v_fail_hi(find(ismember(v_fail_hi,p_inc_hi)));
        inc_hi_fail_lo=v_fail_lo(find(ismember(v_fail_lo,p_inc_hi)));
        inc_lo_fail_hi=v_fail_hi(find(ismember(v_fail_hi,p_inc_lo)));
        inc_lo_fail_lo=v_fail_lo(find(ismember(v_fail_lo,p_inc_lo)));
        dec_hi_fail_hi=v_fail_hi(find(ismember(v_fail_hi,p_dec_hi)));
        dec_hi_fail_lo=v_fail_lo(find(ismember(v_fail_lo,p_dec_hi)));
        dec_lo_fail_hi=v_fail_hi(find(ismember(v_fail_hi,p_dec_hi)));
        dec_lo_fail_lo=v_fail_lo(find(ismember(v_fail_lo,p_dec_hi)));
        
        %group
        cluster1 = [inc_hi_pass_hi;inc_lo_pass_lo;dec_lo_fail_lo;dec_hi_fail_hi]; %y=x
        cluster2 = [inc_hi_fail_hi;inc_lo_fail_lo;dec_lo_pass_lo;dec_hi_pass_hi]; %y=-x
        cluster3= [inc_lo_fail_hi;dec_lo_pass_hi];
        cluster4= [inc_lo_pass_hi;dec_lo_fail_hi];
        cluster5= [inc_hi_fail_lo;dec_hi_pass_lo];
        cluster6= [inc_hi_pass_lo;dec_hi_fail_lo];
        cluster_indices = zeros(length(ticker),1);
        cluster_indices(cluster1)=1;
        cluster_indices(cluster2)=2;
        cluster_indices(cluster3)=3;
        cluster_indices(cluster4)=4;
        cluster_indices(cluster5)=5;
        cluster_indices(cluster6)=6;
        %A
        for m = 1:length(ticker_full)
            ticker_ind = find(ticker==ticker_full(m));
            group_m = cluster_indices(ticker_ind);
            % if ~isempty(group_m)
            %     A(m,m)=A(m,m)+1;
            % end
            for n =1:m-1
                ticker_ind_n = find(ticker==ticker_full(n));
                group_n = cluster_indices(ticker_ind_n);
                if group_m==group_n
                    A(m,n)=A(m,n)+1;
                    A(n,m)=A(n,m)+1;
                end
            end
        end
    end
%%
%take out zeros
B = A;
for i = 1:length(ticker_full)
    B(i,i)=0;
end
zero_ind=find(~sum(B,2));
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
    return_recent24(i)=open2open(prices_ticker24,recent_date24(i),spy_price,1);
    if ~isempty(votes_ticker23)
        recent_date23(i)=votes_ticker23(1,3);
        percent_recent23(i)=mean(votes_ticker23(:,6));
        return_recent23(i)=open2open(prices_ticker24,recent_date23(i),spy_price,1);
    end
end
%%
d = sum(A,2);
P=eye(size(A))+(1/max(d))*A;
[theta,sigma]= graphicalLasso(P,1/max(d),1e03,1e-06);

A_new = zeros(length(ticker_full));
for i = 1:length(ticker_full)
    for j = 1:i
        if theta(i,j)~=0
            A_new(i,j)=1;
        end
        if theta(j,i)~=0
            A_new(j,i)=1;
        end
    end
end

%%
%%
A_mat=A_new;
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
error = abs((y_guess-actual_returns)./actual_returns);
PnL = sum(sign(y_guess).*actual_returns)*ones(length(ticker_full),1);
final_mat=[y_guess,actual_returns]; 
%%
ticker_text = unique(votes.Ticker(find(ismember(votes.TickerID,ticker_full))));
final_table = table(ticker_text,y_guess,actual_returns,PnL,'VariableNames',{'Company','Expected Return', 'Return', 'PnL'});
disp(final_table);
disp(length(find(~y_guess)));