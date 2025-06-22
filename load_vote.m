opts_v = detectImportOptions('proposals.xlsx');
opts_v = opts_v.setvaropts('Date','InputFormat','M/d/yyyy','DateTimeFormat','dd-MMM-yyyy');
votes = readtable('proposals.xlsx',opts_v);

%get vote date data the same as price date data
vote_month=datetime(votes.Date,"Format",'MM');
vote_month=string(vote_month);
vote_day=datetime(votes.Date,"Format",'dd');
vote_day=string(vote_day);
votes_date=append(string(votes.Year),vote_month,vote_day);
votes.DATE=double(votes_date);

%Assign each ticker a numerical value
text_v=votes.Ticker;
[uniqueTickerv,~,ids]=unique(text_v,'sort');
votes.TickerID=ids;


writetable(votes,'votes.csv');