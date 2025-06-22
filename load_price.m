%This script loads pricing data from 1999-2024 and filters for 2006-2024
%This makes dataset smaller and reduces run time
clear
opts = detectImportOptions('ag8zaitw1n04dljt.csv');
opts = opts.setvaropts('date','InputFormat','M/d/yyyy','DateTimeFormat','dd-MMM-yyyy');
prices = readtable("ag8zaitw1n04dljt.csv",opts);


%Dates stored in excel format so need to extract the year, month, day
price_year=datetime(prices.date,"Format",'yyyy');
price_year=string(price_year);


price_month=datetime(prices.date,"Format",'MM');
price_month=string(price_month);


price_day=datetime(prices.date,"Format",'dd');
price_day=string(price_day);

price_date=append(price_year,price_month,price_day);

price_year=double(price_year);
price_month=double(price_month);
price_day=double(price_day);
price_date=double(price_date);

%Add new columns to data with year, month, day
prices.year =price_year;
prices.month =price_month;
prices.day =price_day;
prices.DATE =price_date;

%Filter
price_year_ind=find(price_year>=2006);
prices=prices(price_year_ind,:);

%Filter companies that at some point had the same ticker as companies from
%proxymonitor
remove_comnam = find(ismember(prices.COMNAM,{'BATH & BODY WORKS INC','LA BARGE INC','LANDBRIDGE COMPANY LLC','TAIWAN GREATER CHINA FUND','SHELTON GREATER CHINA FUND','MOVIE STAR INC N Y','WASHINGTON MUTUAL INC','BAKER MICHAEL CORP','CORESITE REALTY CORP','CORTEX PHARMACEUTICALS INC'}));
prices(remove_comnam,:)=[];

%Filter columns
prices=removevars(prices,{'ACCOMP','ACPERM','ASK','ASKHI','BID','BIDLO','CFACPR','CFACSHR','DCLRDT','DISTCD','DLSTCD','EXCHCD','FACPR','FACSHR','HEXCD','ISSUNO','NWPERM','NAMEENDT','NCUSIP','SECSTAT','TICKER',});

%Make tickers the newest symbol
prices.TSYMBOL=fix_tickers(prices);

%Save new data
writetable(prices,'prices.csv');