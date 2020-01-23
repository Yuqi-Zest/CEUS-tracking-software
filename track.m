function [ fna1,rectsA1]=track(img,pos,CutPos,hData,cfn,bsfn,esfn,pp,method)
if method<7 
    [fna1,rectsA1]=TKL(img,pos,CutPos,hData,cfn,bsfn,esfn,pp,method);
else
    [fna1,rectsA1]=CARD(img,pos,CutPos,hData,cfn,bsfn,esfn,pp,method);
end
end

function[ fna1,rectsA1]=TKL(img,pos,CutPos,hData,cfn,bsfn,esfn,pp,method)
if pp==1
    fna1=zeros(cfn-bsfn,1);
    rectsA1=zeros(cfn-bsfn,4);
    for i=1:cfn-bsfn
        if  rem(i,10)==1
            bboxPoints = bbox2points(pos);
            if pos(3)==0 ||pos(4)==0
                return
            end
            if pos(1)+pos(3)>=size(img,2) || pos(2)+pos(4)>=size(img,1)||pos(2)>=size(img,1) ||pos(1)>=size(img,2)||pos(1)<1||pos(2)<1
                return
            end
            switch method
                  case 1
                    points = detectMinEigenFeatures(img);
                case 6
                    points = detectORBFeatures(img);%,'NumLevels',2,'ScaleFactor',1.05);
                case 2
                    points = detectFASTFeatures(img); %,'MinContrast',0.1,'MinQuality',0.1);
                case 3
                    points =detectBRISKFeatures(img); %,'MinContrast',0.1,'MinQuality',0.1,'NumOctaves' ,2);
                case 4
                    points = detectSURFFeatures(img); %,'MetricThreshold' ,400,'NumScaleLevels',3,'NumOctaves',2);
                case 5
                    points = detectMSERFeatures(img);
            end
            if isempty(points)
                return
            end
            points = points.Location;
            pointTracker = vision.PointTracker('MaxBidirectionalError', 2);
            initialize(pointTracker, points, img);
            oldPoints=points;
        end
        img=im2double(rgb2gray(imcrop(read(hData,cfn-i),CutPos)));
        img=min(max(img,0),1);
        %         img = PlugPlayADMM_general(img,A,lambda,method,opts);
        [points, isFound] = step(pointTracker, img);
        visiblePoints = points(isFound, :);
        oldInliers = oldPoints(isFound, :);
        if size(visiblePoints, 1) >= 3
            [xform, oldInliers, visiblePoints] = estimateGeometricTransform(...
                oldInliers, visiblePoints, 'similarity', 'MaxDistance', 4);
            
            % Apply the transformation to the bounding box points
            bboxPoints = transformPointsForward(xform, bboxPoints);
            [xlim,ylim]= boundingbox(polyshape(bboxPoints));
            fna1(cfn-i-bsfn+1)=cfn-i;
            pos=[xlim(1),ylim(1),xlim(2)-xlim(1),ylim(2)-ylim(1)];
            rectsA1(cfn-i-bsfn+1,:)=pos+[CutPos(1),CutPos(2),0,0];
            oldPoints = visiblePoints;
            if size(oldPoints,1)<4
                break
            end
            setPoints(pointTracker, oldPoints);
        else
            break
        end
    end
else
    fna1=zeros(esfn-cfn,1);
    rectsA1=zeros(esfn-cfn,4);
    for i=cfn+1:esfn
        if rem((i - cfn) ,10)==1
            bboxPoints = bbox2points(pos);
            if pos(3)==0 ||pos(4)==0
                return
            end
            if pos(1)+pos(3)>=size(img,2) || pos(2)+pos(4)>=size(img,1)||pos(2)>=size(img,1) ||pos(1)>=size(img,2)||pos(1)<3||pos(2)<3
                return
            end
            switch method
               case 1
                    points = detectMinEigenFeatures(img);
                case 6
                    points = detectORBFeatures(img);%,'NumLevels',2,'ScaleFactor',1.05);
                case 2
                    points = detectFASTFeatures(img); %,'MinContrast',0.1,'MinQuality',0.1);
                case 3
                    points =detectBRISKFeatures(img); %,'MinContrast',0.1,'MinQuality',0.1,'NumOctaves' ,2);
                case 4
                    points = detectSURFFeatures(img); %,'MetricThreshold' ,400,'NumScaleLevels',3,'NumOctaves',2);
                case 5
                    points = detectMSERFeatures(img);
            end
            if isempty(points)
                return
            end
            points = points.Location;
            pointTracker = vision.PointTracker('MaxBidirectionalError', 2);
            initialize(pointTracker, points, img);
            oldPoints=points;
        end
        img=im2double(rgb2gray(imcrop(read(hData,i),CutPos)));
        img= min(max(img,0),1);
        %                 img = PlugPlayADMM_general(img,A,lambda,method,opts);
        [points, isFound] = step(pointTracker, img);
        visiblePoints = points(isFound, :);
        oldInliers = oldPoints(isFound, :);
        if size(visiblePoints, 1) >= 3
            [xform, oldInliers, visiblePoints] = estimateGeometricTransform(...
                oldInliers, visiblePoints, 'similarity', 'MaxDistance', 4);
            bboxPoints = transformPointsForward(xform, bboxPoints);
            [xlim,ylim]= boundingbox(polyshape(bboxPoints));
            fna1(i-bsfn+1)=i;
            rectsA1(i-bsfn+1,:)=[xlim(1)+CutPos(1),ylim(1)+CutPos(2),xlim(2)-xlim(1),ylim(2)-ylim(1)];
            oldPoints = visiblePoints;
            if size(oldPoints,1)<4
                break
            end
            setPoints(pointTracker, oldPoints);
        else
            break
        end
    end
end
end

function [fna1,rectsA1]=CARD(stdimg,pos,CutPos,hData,cfn,bsfn,esfn,pp,method)
switch method
    case 7
        if ~exist('./CARD-master/config/card_config_256bit.bin','file')
            errordlg('CARD has not been correctly installed, please re-select');
            return;
        end
        card_config_binary_ptr = card_config_load_mex('./CARD-master/config/card_config_256bit.bin');
    case 8
        if ~exist('./CARD-master/config/card_config_128bit.bin','file')
            errordlg('CARD has not been correctly installed, please re-select');
            return;
        end
        card_config_binary_ptr = card_config_load_mex('./CARD-master/config/card_config_128bit.bin');
%     case 9
%         card_config_binary_ptr = card_config_load_mex('./config/card_config_64bit.bin');
end
th_ratio=0.6;
if pp==1
    bboxPoints = bbox2points(pos);
    % BW=roipoly(image,bboxPoints(:,1),bboxPoints(:,2));
    [pnts_info1, desc1] = card_compact_and_realtime_descriptor_mex(stdimg, card_config_binary_ptr);
    pnts1=pnts_info1([1 2],:);
    
    fna1=zeros(cfn-bsfn,1);
    rectsA1=zeros(cfn-bsfn,4);
    for i=1:cfn-bsfn
        img=im2double(rgb2gray(imcrop(read(hData,cfn-i),CutPos)));
        img=min(max(img,0),1);
        %         img = PlugPlayADMM_general(img,A,lambda,method,opts);
        [pnts_info2, desc2] = card_compact_and_realtime_descriptor_mex(img, card_config_binary_ptr);
        pnts2= pnts_info2([1 2], :);
        k = 2; % top k near neighbors
        [idx, d] = hamming_enn_mex(desc1, desc2, k);
        flag = (d(1,:) < (d(2,:) * th_ratio))';
        match_idx=[];
        match_idx(flag) = idx(1,flag)';
        flag=match_idx>0;
        if isempty(flag)
            break;
        end
        oldInliers = pnts1(:,flag); %+[pos(1);pos(2)];
        visiblePoints=pnts2(:,match_idx(flag));
        if size(visiblePoints, 2) >= 5
             [xform, ~, ~] = estimateGeometricTransform(...
                oldInliers', visiblePoints', 'similarity', 'MaxDistance', 4);
            bboxPoints = transformPointsForward(xform, bboxPoints);
            [xlim,ylim]= boundingbox(polyshape(bboxPoints));
            %pos=[xlim(1),ylim(1),xlim(2)-xlim(1),ylim(2)-ylim(1)];
            % bboxPoints = bbox2points(pos);
            % BW=roipoly(img,bboxPoints(:,1),bboxPoints(:,2));
            fna1(cfn-i-bsfn+1)=cfn-i;
            rectsA1(cfn-i-bsfn+1,:)=[xlim(1)+CutPos(1),ylim(1)+CutPos(2),xlim(2)-xlim(1),ylim(2)-ylim(1)];
            pnts_info1=pnts_info2;
            desc1=desc2;
            %[pnts_info1, desc1] = card_compact_and_realtime_descriptor_mex(img, card_config_binary_ptr);
            pnts1=pnts_info1([1 2],:);
        else
            break;
        end
    end
else
    bboxPoints = bbox2points(pos);
    %BW=roipoly(stdimg,bboxPoints(:,1),bboxPoints(:,2));
    %BW=im2bw(BW);
    [pnts_info1, desc1] = card_compact_and_realtime_descriptor_mex(stdimg, card_config_binary_ptr);
    pnts1=pnts_info1([1 2],:);
    
    fna1=zeros(esfn-cfn,1);
    rectsA1=zeros(esfn-cfn,4);
    for i=cfn+1:esfn
        img=im2double(rgb2gray(imcrop(read(hData,i),CutPos)));
        img=min(max(img,0),1);
        %         img = PlugPlayADMM_general(img,A,lambda,method,opts);
        [pnts_info2, desc2] = card_compact_and_realtime_descriptor_mex(img, card_config_binary_ptr);
        pnts2= pnts_info2([1 2], :);
        k = 2; % top k near neighbors
        [idx, d] = hamming_enn_mex(desc1, desc2, k);
        flag = (d(1,:) < (d(2,:) * th_ratio))';
        match_idx=[];
        match_idx(flag) = idx(1,flag)';
        flag=match_idx>0;
        if isempty(flag)
            break;
        end
        oldInliers = pnts1(:,flag);%+[pos(1);pos(2)];
        visiblePoints=pnts2(:,match_idx(flag));
        if size(visiblePoints, 2) >= 5
            [xform, ~, ~] = estimateGeometricTransform(...
                oldInliers', visiblePoints', 'similarity', 'MaxDistance', 4);
            bboxPoints = transformPointsForward(xform, bboxPoints);
            [xlim,ylim]= boundingbox(polyshape(bboxPoints));
            fna1(i-bsfn+1)=cfn-i;
            rectsA1(i-bsfn+1,:)=[xlim(1)+CutPos(1),ylim(1)+CutPos(2),xlim(2)-xlim(1),ylim(2)-ylim(1)];
            pnts_info1=pnts_info2;
            desc1=desc2;
            pnts1=pnts_info1([1 2],:);
        else
            
           break;
        end
    end
end
end