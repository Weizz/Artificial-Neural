function flag = myimdilate(path)
    tic;    %計時器開始
    
    isPlatDetactected = 0; %#ok<NASGU>  %定位到車牌旗幟
    
    img_orig = imread(path);    %自路徑 path(字串)讀取圖片
    
    img_gray = rgb2gray(img_orig);  %灰階化
    
    img_medfilt = medfilt2(img_gray);   %中值慮波
    
    img_edge = edge(img_medfilt,'Prewitt','vertical');  %水平prewitt邊緣偵測
    
    img_dilate = DilateProcess(img_edge);   %圖片經過一次膨脹.一次侵蝕.五次膨脹
    
    [labels, num_labels] = bwlabel(img_dilate, 4);  %區塊標籤化 相鄰白色點設為同區塊
    
    regions = regionprops(labels,'BoundingBox');    %regions為各區塊外接方形
    
    proportions = proportionCaculate(regions, num_labels);  %proportions為各方型長寬比
    
    candidateRegionsIndex = pickUpCandidate(proportions, labels, num_labels, img_gray); %以大小.長寬比為條件初步篩選後選區域
    
    platLikeRank = zeros(1,length(candidateRegionsIndex));  %宣告platLikeRank, 用來放排名過後的候選區域
    if length(candidateRegionsIndex) > 1    %如果候選區域大於1, 排名候選區域
        platLikeRank = platDetect(candidateRegionsIndex, regions, img_medfilt);
    elseif length(candidateRegionsIndex) == 1
        platLikeRank = candidateRegionsIndex(1);
    else 
        disp('Cannot found plat.');
    end
    
    isPlatDetactected = length(candidateRegionsIndex) >= 1;
    plat_img = [];
    if isPlatDetactected
        plat_img = imcrop(img_medfilt, regions(platLikeRank(1)).BoundingBox);   %割出排名第一的區域
    end
    
    
    subplot(3,3,1), imshow(img_orig),title('原始圖像'),
    subplot(3,3,2), imshow(img_gray),title('灰階'), 
    subplot(3,3,3), imshow(img_medfilt),title('中值綠波'),
    subplot(3,3,4), imshow(img_edge),title('邊緣'),
    subplot(3,3,5), imshow(img_dilate),title('膨脹+侵蝕+膨脹*5'),
    if isPlatDetactected
        hold on;
        %for i = 1:length(candidateRegionsIndex)            %取消註解此區觀看所有區塊
        %    rectangle('Position', regions(candidateRegionsIndex(i)).BoundingBox, 'EdgeColor', 'g');
        %end
        rectangle('Position', regions(platLikeRank(1)).BoundingBox, 'EdgeColor', 'g');
        hold off;
    end
    subplot(3,3,6), imshow(plat_img),title('車牌'),
    flag = isPlatDetactected;
    toc;    %計時結束
    
    function img_dilated = DilateProcess(edged_img)
        se = strel('line',5,0);
        dilate = imdilate(edged_img, se);
        erode = imerode(dilate, se);
        dilate2 = imdilate(erode, se);    
        for times = 0:4
            dilate2 = imdilate(dilate2, se);
        end
        img_dilated = dilate2;
    end

    function proportionOfregions = proportionCaculate(allRegions, numOflabels)
        proportionOfregions = zeros(1, numOflabels);
        for index_regions=1:numOflabels
            proportionOfregions(index_regions) = allRegions(index_regions).BoundingBox(3)/allRegions(index_regions).BoundingBox(4);
        end
    end

    function candidates = pickUpCandidate(region_proportions, region_labels, numOflabels, img_g)
        candidates = [];
        count = 1;
        [w, h] = size(img_g);
        img_size = w*h;
        for index = 1:numOflabels
            if (region_proportions(index)>=2.3) && (region_proportions(index)<=5) && sum(sum((region_labels==index)))>=img_size*0.009   %8000
                candidates(count) = index;
                count = count+1;
                disp(['size of location ' num2str(index) ' is ' num2str(sum(sum(region_labels==index))) ' ,proportion is ' num2str(region_proportions(index))]);
            end
        end
        disp(candidates);
    end

    function platLikeRanks = platDetect(candidates, allRegions, pic)
        pic = edge(im2bw(histeq(pic)),'Prewitt','vertical');
        len = length(candidates);
        platLikeRanks = zeros(len, 1); %#ok<NASGU>
        point = zeros(len, 1);
        for num = 1:len
            a = imcrop(pic, allRegions(candidates(num)).BoundingBox);
            [h, ~] = size(a);
            b = sum(a')>40; %#ok<UDIM>
            disp(['number' num2str(num) ' candidate have ' num2str(sum(b)) ' row bigger than 40 , proportion is :' num2str(sum(b)/h)]);
            point(num) = sum(b)/h;
        end
        disp(' ');
        if max(point) == min(point)
            location = zeros(len, 2);
            for num = 1:len
                location(num, :) = [candidates(num), allRegions(candidates(num)).BoundingBox(2)];
                disp(['candidate' num2str(num) ' is region ' num2str(candidates(num)) ' y-axis is ' num2str(allRegions(candidates(num)).BoundingBox(2))]);
            end
            location = sortrows(location, 2);
            location = flipud(location);
            platLikeRanks = location(:, 1);
            disp(platLikeRanks);
        else
            [~, index] = sort(point);
            platLikeRanks = candidates(index);
            disp(platLikeRanks);
        end
    end
end
