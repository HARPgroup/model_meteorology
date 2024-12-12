function [] = Temp_Monthly_Delta_Change(TDATASET,OUTFOLDER,PPROB)
% Temp_Monthly_Delta_Change('RCP45_2011_2040','2021-2030','P50')

    %PDATASET  = 'PRISM_1927_2025';%'RCP45_2011_2040';
    %OUTFOLDER = '2021-2030';
    %PPROB     = 'P50';
    %INTENSITY = 'KK';

    delta_change   = importdata(strcat('./tas_delta/lseg_delta_tas_',TDATASET,'_',PPROB,'.csv'));
    
    I_process_lseg = 0;
    C_process_lseg = importdata('./pr_delta/allP6.land');

    PSYEAR = 1991;
    PEYEAR = 2000;

    mkdir (strcat('./WSM_INPUT/',TDATASET(1:5),'_',PPROB,'/',OUTFOLDER,'/'))

    validation  = zeros(13,1);

    nlseg = size(delta_change.textdata,1);

    for ilseg = 2:nlseg
        lseg = delta_change.textdata(ilseg,1);
        
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

        baseline = importdata(strcat('./NLDAS2/N20150521J96/1984-2014/',char(lseg),'.TMP'));

        temp = find(baseline.data(:,1)==PSYEAR);
        ds = temp(1,1);
        temp = find(baseline.data(:,1)==PEYEAR+1);
        de = temp(1,1)-1;
        clear temp;

        xdata = baseline.data(ds:de,1:5);
        
        data  = xdata;
        
        %for imm = 1:12
        %    %[ imm delta_change.data(ilseg-1,imm+1) ]
        %    [order] = find(xdata(:,2) == imm);
        %    data(order,5) = xdata(order,5) + delta_change.data(ilseg-1,imm+1);
        %end

        fid = fopen(strcat('./WSM_INPUT/',TDATASET(1:5),'_',PPROB,'/',OUTFOLDER,'/',char(lseg),'.TMP'), 'wt');
        for ihh = 1:size(data,1)
            data(ihh,5) = data(ihh,5) + delta_change.data(ilseg-1,data(ihh,2)+1);
            fprintf(fid, '%d, %02d, %02d, %02d, %1.4E\n',data(ihh,1:5));
        end
        for imm = 1:12
            [order] = find(data(:,2) == imm);
            validation(imm,1) = mean(data(order,5)) - mean(xdata(order,5));
        end
        validation(13,1) = mean(data(:,5)) - mean(xdata(:,5));
        fprintf('%s,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f\n',char(lseg),validation(1:13,1));
    end

end