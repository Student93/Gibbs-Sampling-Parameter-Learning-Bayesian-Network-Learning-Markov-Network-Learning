format long;

out_file = fopen('bayesianHepar.txt','w');
out_file1 = fopen('bayesianHeparMarginal.txt','w');
DLL =0.0;


fileID = fopen('A3-data/hepar2.bif');
c = textscan(fileID,'%s ');
c = c{1,1};
start = 6;

s = size(c,1);

variables = containers.Map('KeyType','int32','ValueType','char');
variableScopeSize = containers.Map('KeyType','int32','ValueType','int32');
attributes = containers.Map('KeyType','int32','ValueType','any');
mapping = containers.Map('KeyType','char','ValueType','int32');
parents = containers.Map('KeyType','int32','ValueType','any');
numRows = containers.Map('KeyType','int32','ValueType','any');
probability = containers.Map('keyType','int32','ValueType','any');
parentIndex = containers.Map('KeyType','int32','ValueType','any');
factorTable = containers.Map('KeyType','int32','ValueType','any');
DLL = 0.0;
count = 0;
f = 1;

while f==1
    count = count+1;
    variables(count) = c{start,1};
    mapping(c{start,1}) = count;
    
    % now start is on above variable scope size 
    start = start + 5;
    
    variableScopeSize(count) = str2num(c{start,1});
    
    % now start on first variable name
    start = start + 3;
    t = cell(1,1);
    for i=1:variableScopeSize(count)-1
        k = c{start,1};
        k = k(1:size(k,2)-1);
        t = [t, [k]];
        start = start + 1;
    end
    
    k = c{start,1};
    t = [t,[k]];
    t(1) = [];
    attributes(count) = t;
        
    start = start + 4;
    
   if(strcmp(c{start-1,1},'probability')==1)
       f=0;
       start = start - 1;
   end
    
end


count = 0;
f = 1;

% on first variable node

start = start + 2;

while f==1
    
    index = mapping(c{start,1});
    t = cell(1,1);
   
    if(strcmp(c{start+1,1},')')==1)
        parents(index) = [];
        numRows(index) = 0;
        start = start + 7 + variableScopeSize(index);
    else
        tempStart = start + 1;
        
        while strcmp(c{tempStart,1},')')==0
            tempStart = tempStart + 1;
        end
        
        tempStart = tempStart - 1;
        num_rows = 1;
        
        for i=start+2:tempStart-1
            k = c{i,1};
            k = k(1:size(k,2)-1);
            num_rows = num_rows * variableScopeSize(mapping(k));
            t = [t,[k]];
            
        end
        val_row = tempStart - (start+2) + 1 + variableScopeSize(index);
        num_rows = num_rows * variableScopeSize(mapping(c{tempStart,1}));
        numRows(index) = num_rows;
        start = tempStart + 2 + val_row*num_rows + 4;
        
        t = [t,c{tempStart,1}];
        t(1) = [];
        parents(index) = t;
        
        
    end
    
    
    count = count + 1;
    
    
    
    if(count == size(variables,1))
        f=0;
    end
    
end

data = importdata('A3-data_2/hepar2_small.dat');
dataAttr = data{1,1};
dataAttr = textscan(dataAttr,'%s');
dataAttr = dataAttr{1,1};
order = zeros(size(dataAttr,1),1);

for i =1:size(dataAttr,1)
   order(i,1) = mapping(char(dataAttr(i)));
end

orderMap = containers.Map('KeyType','int32','ValueType','int32');

for i=1:size(dataAttr,1)
   orderMap(order(i,1)) = i;
end
dataSize = size(data,1);

data = data(2:dataSize);

dataSize = size(data,1);

varSize = size(variables,1);

samples  = cell(dataSize,varSize);

for i=1:dataSize
    samples(i,:) = strsplit(data{i,1});
end



% learn parameters (CPTs)
tic


for i=1:size(variables,1)
    i
    if size(parents(i),2) == 0
        % no parent
        tempTruthValue = zeros(1,variableScopeSize(i));
        index = orderMap(i);
        varSize = variableScopeSize(i);
        val = attributes(i);
        for m = 1:size(samples,1)
            indexNum = -1;
            for n=1:varSize
                val1 = val(1,n);
                val2 = samples(m,index);
                if strcmp(val1,val2)==1
                    indexNum = n;
                    
                    break;
                end
            end
            
            tempTruthValue(1,indexNum) = tempTruthValue(1,indexNum) + 1;
           
            
        end
        
        for m=1:varSize
           
           x = tempTruthValue(1,m) + 1;
           y = size(samples,1) + varSize;
           tempTruthValue(1,m)= double(x)/double(y);
        end
        mapSample = containers.Map('KeyType','char','ValueType','any');
        factorTable(i)  = mapSample;
        probability(i) = tempTruthValue;
        parentIndex(i) = [];
        
        
    else
        % create index table
        tempTruthTable = zeros(numRows(i),size(parents(i),2));
        tempTruthValue = zeros(numRows(i),variableScopeSize(i));
        tempParentCount = zeros(numRows(i),1);
        parentOrder = zeros(1,size(parents(i),2));
        tempIndex = ones(1,size(parents(i),2));
        parOfCurrIndex = parents(i);
        parSize = size(parents(i),2);
        x = parents(i);
        mapSample = containers.Map('KeyType','char','ValueType','any');
        for j=1:numRows(i)
    
            tempTruthTable(j,:) = tempIndex;
            tempStr = '';
            for k=1:parSize
               index = mapping(char(parOfCurrIndex(1,k)));
               parentOrder(1,k) = orderMap(index);
               tempAttr = attributes(index);
               attrIndex = tempIndex(1,k);
               tempStr = strcat(tempStr,tempAttr(1,attrIndex));
               
           end
           
           mapSample(char(tempStr)) = j;
            
            
            tempIndex(1,1) = tempIndex(1,1) + 1;
            
            if parSize==1
                
                if tempIndex(1,1) == variableScopeSize(mapping(char(x(1,1)))) + 1
                    tempIndex(1,1) = 1;
                end
            else
               
                for k = 2:parSize
                    if tempIndex(1,k-1) == variableScopeSize(mapping(char(x(1,k-1)))) + 1
                        tempIndex(1,k) = tempIndex(1,k) + 1;
                        tempIndex(1,k-1) = 1;
                    end
                    
                end
            end
            
        end
        factorTable(i) = mapSample;
       
        % I have all indexes and and 1 array for storing values
        % generate a map to get index
        
        
       
        
        attr = attributes(i);
        var = variableScopeSize(i);
        sP = size(parents(i),2);
        for j=1:size(samples,1)
            
            %create current sample string
            tempStr = '';
            for k=1:sP
                temp1 = parentOrder(1,k);
                tempStr = strcat(tempStr,samples(j,temp1));
            end
            
            rootIndex = orderMap(i);
            rootValue = samples(j,rootIndex);
            numIndex = -1;
            
            for k=1:var
               
                if strcmp(attr(1,k),rootValue)==1
                    numIndex = k;
                    break;
                end
 
            end
            
            tempTruthValueIndex = mapSample(char(tempStr));
            tempParentCount(tempTruthValueIndex,1) = tempParentCount(tempTruthValueIndex,1) + 1;
            tempTruthValue(tempTruthValueIndex,numIndex) = tempTruthValue(tempTruthValueIndex,numIndex) + 1;
            
            
            
        end
        
        for j=1:numRows(i)
            x1 = tempParentCount(j,1) + variableScopeSize(i);
            for k=1:variableScopeSize(i)
                y1 = tempTruthValue(j,k) + 1;
                tempTruthValue(j,k) = double(y1)/double(x1);
            end
        end
        
        
        probability(i) = tempTruthValue;
        parentIndex(i) = tempTruthTable;
        
    end
    
    
end

toc


% printing to file

count = size(variables,1);

for i=1:count
    ttVarName = variables(i);
    fprintf(out_file,'probability ( %s',ttVarName);
    
    ttParentScope = parents(i);
    
    ttParentScopeSize = size(ttParentScope,2)
    if ttParentScopeSize == 0
        fprintf(out_file,' ) {\ntable ');
        ttempProbability = probability(i);
        ttSize = size(ttempProbability,2);
        for j=1:ttSize-1
           fprintf(out_file,'%f, ',ttempProbability(1,j)); 
        end
        fprintf(out_file,'%f;\n}\n',ttempProbability(1,ttSize));
        
    else
        
        fprintf(out_file,' | ');
        for j=1:ttParentScopeSize-1
            
            fprintf(out_file,'%s, ', ttParentScope{1,j});
        end
        
        fprintf(out_file,'%s ){\n',ttParentScope{1,ttParentScopeSize});
        
        ttParentIndex = parentIndex(i);
        fprintf(out_file,'(')
        ttParentIndexSize = size(ttParentIndex,1);
        for j=1:ttParentIndexSize
            for k=1:ttParentScopeSize-1
                ttMapping = mapping(char(ttParentScope(1,k)));
                ttValue= attributes(ttMapping);
                ttValue1=ttValue(1,ttParentIndex(j,k));  
                fprintf(out_file,'%s, ', ttValue1{1});
            end
            
            ttMapping = mapping(char(ttParentScope(1,ttParentScopeSize)));
            ttValue= attributes(ttMapping);
            ttValue1=ttValue(1,ttParentIndex(j,ttParentScopeSize));  
            fprintf(out_file,'%s) ', ttValue1{1});
            
            ttempProbability = probability(i);
            ttSize = size(ttempProbability,2);
            for j1=1:ttSize-1
               fprintf(out_file,'%f, ',ttempProbability(j,j1)); 
            end
            if j~=ttParentIndexSize
                fprintf(out_file,'%f;\n(',ttempProbability(j,ttSize));
            else
                fprintf(out_file,'%f;\n',ttempProbability(j,ttSize));
            end
            
        end
        fprintf(out_file,'}\n');
        
        
        
        
    end
    
    
   
    
end





%save('probability12.mat','probability');
%save('Index12.mat','parentIndex');




%load probability.mat
%load Index.mat
%load factorTable.mat


countChar = 0;
totalChar = 0;
testData = importdata('hepar_test.dat');
truthData = importdata('hepar_TrueValues.dat');
testSize = size(testData,1);

for i=2:11
    i
    
    testSample = testData(i);
    testSample = testSample{1,1};
    testSample = strsplit(testSample);
    
    truthSample = truthData(i);
    truthSample = truthSample{1,1};
    truthSample = strsplit(truthSample);
  
    % find all question marks indexes in test sample
    
    sampleIndex = [];
    actualIndex = [];
    sampleSize = size(testSample,2);
    
    for j = 1:sampleSize
        
        if strcmp(testSample(1,j), '?')==1
            sampleIndex = [sampleIndex,j];
            actualIndex = [actualIndex,order(j)];
        end
    end
    
    % find initial sample
    testGibbsSample = testSample;
   
    counterOnIndex = 1;
    
    
    for j=1:sampleSize
       
        if strcmp(testGibbsSample(1,j), '?')==1
           
            
            tempActualIndex = actualIndex(1,counterOnIndex);
            tempSize = variableScopeSize(tempActualIndex);
            attr = attributes(tempActualIndex);
            tempRand = randi([1 tempSize],1,1);
            testGibbsSample(1,j)= attr(1,tempRand);
            counterOnIndex = counterOnIndex + 1;
            
        end
        
    end
    
   
    gibbsSamples =containers.Map('KeyType','int32','ValueType','any');
    countSamples = 1;
    gibbsSamples(1) = testGibbsSample;
    countOnIndex = 1;
    sampleIndexSize= size(sampleIndex,2);
    count = size(variables,1);
    %initialize multiple
   
    while countSamples <5000
      
        if countOnIndex > sampleIndexSize
            countOnIndex = 1;
        end
        
        
        
        tempActualIndex = actualIndex(1,countOnIndex);
        actualAttr = attributes(tempActualIndex);
        varSize1 = variableScopeSize(tempActualIndex);
        multiple = zeros(varSize1,1);
        % create other multiple
      
        for k=1:count
           
            if k ~=tempActualIndex
                
                tempParent = parents(k);
                tempParentSize = size(tempParent,2);
                
                orderVar = orderMap(k);
                tempValue = testGibbsSample(1,orderVar);
                
                attr = attributes(k);
                attrSize = variableScopeSize(k);
                tempNumIndex = -1;
                
                for l=1:attrSize
                    if strcmp(attr(1,l),tempValue)==1
                        tempNumIndex = l;
                        break;
                    end
                end
                if tempParentSize ~=0
                    
                    
                    tempStr1 = cell(varSize1,1);
                    
                    for l1 =1:varSize1
                        tempStr1{l1} = '';
                    end
                    
                    for l = 1:tempParentSize
                       temp1 = mapping(char(tempParent(1,l))); 
                       if temp1==tempActualIndex
    
                           for l1=1:varSize1
                               tempStr1{l1} = strcat(tempStr1{l1},actualAttr(1,l1));
                           end
                           
                       else
                           
                           temp2 = orderMap(temp1);
                           
                           for l1=1:varSize1
                               tempStr1{l1} = strcat(tempStr1{l1},testGibbsSample(1,temp2));
                           end
                       
                           
                       end
                       
                       
                       
                    end
                    
                    tempMap = factorTable(k);
                    tempProb = probability(k);
                    
                    for l1=1:varSize1
                        tempMapRow = tempMap(char(tempStr1{l1}));
                        multiple(l1,1) = multiple(l1,1) + log(tempProb(tempMapRow,tempNumIndex));
                    end
                    
                
                else
                    tempProb = probability(k);
                    for l1=1:varSize1
                        multiple(l1,1) = multiple(l1,1) + log(tempProb(1,tempNumIndex));
                    end
                    
                end
            end
            
        end
       
       
          
        
        varSize = variableScopeSize(tempActualIndex);
        tempTable = zeros(varSize,1);
        tempPar = parents(tempActualIndex);
        tempParSize = size(tempPar,2);
        attr = attributes(tempActualIndex);
        if tempParSize ~=0
            tempStr = '';
            for l = 1:tempParSize
               temp1 = mapping(char(tempPar(1,l))); 
               temp2 = orderMap(temp1);
               tempStr = strcat(tempStr,testGibbsSample(1,temp2));

            end

            tempMap = factorTable(tempActualIndex);
            tempMapRow = tempMap(char(tempStr));
            tempProb = probability(tempActualIndex);
            
            for k1=1:varSize
               tempTable(k1,1) = multiple(k1,1) + log(tempProb(tempMapRow,k1)); 
            end
            
            
        else
            
            tempProb = probability(tempActualIndex);
            for k1=1:varSize
               tempTable(k1,1) = multiple(k1,1) + log(tempProb(1,k1)); 
            end
            
        end
        
        totalValue = 0;
        for k=1:varSize
            
            totalValue = totalValue + exp(tempTable(k,1));
            
        end
        
        sumValue = 0.0;
        for k1=1:varSize
            tempTable(k1,1) = double(exp(tempTable(k1,1)))/double(totalValue);
            sumValue = sumValue + tempTable(k1,1);
        end
        
        for k1=1:varSize
            tempTable(k1,1) = double(tempTable(k1,1))/(sumValue);
        end
        
       
        
        cum = 0.0;
        randNum = rand(1,1);
        attrIndex = -1;
        for k1=1:varSize
            cum = cum + tempTable(k1,1);
            if randNum < cum
                attrIndex = k1;
                break;
            end
            
        end
        
        testGibbsSample(1,sampleIndex(countOnIndex)) = attr(1,attrIndex);
        countOnIndex = countOnIndex + 1;
        
        countSamples = countSamples + 1;
       
        gibbsSamples(countSamples) = testGibbsSample;
        
    end
    
    
    actualIndexSize = size(actualIndex, 2);
    
    for j=1:actualIndexSize 
        
        tempActualIndex = actualIndex(1,j);
        tempSampleIndex1 = sampleIndex(1,j);
        tempScopeSize = variableScopeSize(tempActualIndex);
        
        countVar = zeros(tempScopeSize,1);
        
        varMap = containers.Map('KeyType','char','ValueType','int32');
        attr = attributes(tempActualIndex);
        
        for k=1:tempScopeSize
            
            varMap(char(attr(1,k))) = k;
     
        end
        tempVarName = variables(tempActualIndex);
        sampleSize = size(gibbsSamples,1);
        
        for k=1000:sampleSize
           tempSample = gibbsSamples(k); 
           value = tempSample(1,tempSampleIndex1);
           row = varMap(char(value));
           countVar(row,1) = countVar(row,1) + 1;
        end
        
        [x,y] = max(countVar);
        tempSumCountVar = sum(countVar);
        countVar = double(countVar)/double(tempSumCountVar);
        
        %printing
        fprintf(out_file1,'%s\n',attr{1,y});
        fprintf(out_file1,'%s ',tempVarName);

        for ll=1:tempScopeSize

            fprintf(out_file1,'%s:%f ',attr{1,ll},countVar(ll,1));

        end
        fprintf(out_file1,'\n');
        
        
        strValue = truthSample(1,tempSampleIndex1);
        truthRow = varMap(char(strValue));
        
        if y==truthRow
            countChar = countChar + 1
        end
        if countVar(truthRow,1)>0
            DLL = DLL + log(countVar(truthRow,1))
        end
        totalChar = totalChar+1;
    end
    
    fprintf(out_file1,'\n');
end


countChar/totalChar
DLL/10

