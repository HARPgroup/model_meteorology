function [] = Precip_Monthly_Factor_Change(PDATASET,OUTFOLDER,PPROB,INTENSITY)
% Precip_Monthly_Factor_Change('PRISM_1927_2025','2021-2030','P50','KK')
% Precip_Monthly_Factor_Change('PRISM_1927_2025','2021-2030','P50','EV')
% Precip_Monthly_Factor_Change('RCP45_2011_2040','2021-2030','P50','EV')
% Precip_Monthly_Factor_Change('RCP45_2036_2065','2046-2055','P10','KK')

    %PDATASET  = 'PRISM_1927_2025';%'RCP45_2011_2040';
    %OUTFOLDER = '2021-2030';
    %PPROB     = 'P50';
    %INTENSITY = 'KK';

    percent_change   = importdata(strcat('./pr_delta/lseg_delta_pr_',PDATASET,'_',PPROB,'.csv'));
    %intensity_change = importdata(strcat('./breakouts/percentile_breakouts_table_',INTENSITY,'_',PPROB,'.csv'));
    intensity_change = importdata(strcat('./breakouts/percentile_breakouts_table_',INTENSITY,'_ALL','.csv'));
    
    I_process_lseg = 0;
    C_process_lseg = importdata('./pr_delta/allP6.land');

    intensity_threshold = 0.01 * 0.03937;

    DSYEAR = 1991;
    DEYEAR = 2000;

    PSYEAR = 1991;
    PEYEAR = 2000;

    mkdir (strcat('./WSM_INPUT/',PDATASET(1:5),'_',INTENSITY,'_',PPROB,'/',OUTFOLDER,'/'))

    validation  = zeros(12,1);
    prct_range  = zeros(12,11);
    prct_factor = zeros(12,10);


    nlseg = size(percent_change.textdata,1);

    for ilseg = 2:nlseg
        lseg = percent_change.textdata(ilseg,1);
        
        I_process_lseg = 0;
        for ilseg2 = 1:size(C_process_lseg,1)
            if ( strcmp(char(lseg),char(C_process_lseg(ilseg2))) )
                I_process_lseg = 1;
                break
            end
        end
        if ( I_process_lseg == 0 )
            fprintf('%s - skipping\n',char(lseg));
            continue
        end

        prct_volume = zeros(12,10);
        month_volume = zeros(12,1);

        for irow = 2:size(intensity_change.textdata(:,1))
            %[char(intensity_change.textdata(irow,1)) char(lseg)]
            if( strcmp(char(intensity_change.textdata(irow,1)),char(lseg)) )
                break
            end
        end
        irow = irow - 1;

        baseline = importdata(strcat('./NLDAS2/N1505NS1609/1984-2014/',char(lseg),'.PPT'));

        temp = find(baseline.data(:,1)==DSYEAR);
        ds = temp(1,1);
        temp = find(baseline.data(:,1)==DEYEAR+1);
        de = temp(1,1)-1;
        clear temp;

        xdata = baseline.data(ds:de,:);
        xdata(:,6) = [1:1:(de-ds+1)];
        [sdata, order] = sort(xdata(:,5),'ascend');
        sdata = xdata(order,:);
        temp = find(sdata(:,5) >= intensity_threshold);
        sdata = sdata(temp(1,1):size(sdata,1),:);

        for imm = 1:12
            [order] = find(sdata(:,2) == imm);
            mdata = sdata(order,:);
            prct_range(imm,:) = prctile(mdata(:,5),[0:10:100])';
            %prct_range(imm,:) = [min(mdata(:,5)); xprct; max(mdata(:,5))];
            for ihh = 1:size(mdata(:,5))
                for ipct = 1:10
                    if ( mdata(ihh,5) > prct_range(imm,ipct) && mdata(ihh,5) <= prct_range(imm,ipct+1) )
                        prct_volume(imm,ipct) = prct_volume(imm,ipct) + mdata(ihh,5);
                        month_volume(imm) = month_volume(imm) + mdata(ihh,5);
                    end
                end
            end
        end

        for imm = 1:12
            for ipct = 1:10
                %[imm ipct month_volume(imm) percent_change.data(ilseg-1,imm+1)/100 intensity_change.data(irow,ipct+1) prct_volume(imm,ipct)]
                %percent_change.data(ilseg,imm)
                %intensity_change.data(irow,imm)
                %month_volume(imm)
                prct_factor(imm,ipct) = 1.0 + month_volume(imm) * (percent_change.data(ilseg-1,imm+1)/100) * intensity_change.data(irow,ipct+1) / prct_volume(imm,ipct);
                if ( prct_factor(imm,ipct) < 0.0 )
                    prct_factor(imm,ipct)= 0.0;
                end
            end
        end

        temp = find(baseline.data(:,1)==PSYEAR);
        ds = temp(1,1);
        temp = find(baseline.data(:,1)==PEYEAR+1);
        de = temp(1,1)-1;
        clear temp;

        fid = fopen(strcat('./WSM_INPUT/',PDATASET(1:5),'_',INTENSITY,'_',PPROB,'/',OUTFOLDER,'/',char(lseg),'.PPT'), 'wt');
        data = baseline.data(ds:de,:);
        for ihh = 1:size(data,1)
            for ipct = 1:10
                if ( data(ihh,5) > prct_range(data(ihh,2),ipct) && data(ihh,5) <= prct_range(data(ihh,2),ipct+1) )
                    break
                end
            end
            data(ihh,5) = data(ihh,5) * prct_factor(data(ihh,2),ipct);
            fprintf(fid, '%d, %02d, %02d, %02d, %1.4E\n',data(ihh,1:5));
        end
        for imm = 1:12
            [order] = find(data(:,2) == imm);
            validation(imm,1) = (sum(data(order,5))/sum(xdata(order,5)) - 1)*100;
        end
        fprintf('%s,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f\n',char(lseg),validation(1:12,1));
    end

end
