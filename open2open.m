%calculates the open to "plus" day open market excess return for a particular
%company with a particular initial date "date"

function market_excess_return = open2open(price_ticker,date,spy,plus)
            spy_ind = find(spy(:,1)==date,1);
            spy_p=spy(spy_ind,3);
            spy_p_next=spy(spy_ind+plus,3);
            market_return = log(spy_p_next/spy_p);
            open_ind=find(price_ticker(:,3)==date);         
            l=length(open_ind);
            open_ind=open_ind(1);
            open_price = price_ticker(open_ind,4);
            open_price_next= price_ticker(open_ind+l*(plus),4);
            raw_return =log((open_price_next)/(open_price));
            market_excess_return=raw_return-market_return;
end

