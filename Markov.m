format long;
%out_file = fopen('markovandes1.txt','w');
out_file1 = fopen('markovandesMarginal3.txt','w');

DLL = 0.0;
%{
fileID = fopen('andes.bif');
c = textscan(fileID,'%s ');
c = c{1,1};
start = 6;

s = size(c,1);

variables = containers.Map('KeyType','int32','ValueType','char');
variableScopeSize = containers.Map('KeyType','int32','ValueType','int32');
attributes = containers.Map('KeyType','int32','ValueType','any');
mapping = containers.Map('KeyType','char','ValueType','int32');
parents = containers.Map('KeyType','int32','ValueType','any');
factorScope = containers.Map('KeyType','int32','ValueType','any');
numRows = containers.Map('KeyType','int32','ValueType','any');
factorTable = containers.Map('KeyType','int32','ValueType','any');
factorTableValue = containers.Map('KeyType','int32','ValueType','any');
factorMap = containers.Map('KeyType','int32','ValueType','any');
featureAvg = containers.Map('KeyType','int32','ValueType','any');
featureExp = containers.Map('KeyType','int32','ValueType','any');
varToFactor = containers.Map('KeyType','int32','ValueType','any');
expSamples = containers.Map('KeyType','int32','ValueType','any');
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
% create factor nodes scope
for i=1:count
   
    tempSize = 1 + size(parents(i),2);
    tempScope =  cell(1,1);
    tempScope = [tempScope, char(variables(i))];
    par = parents(i);
    for j=2:tempSize
        tempScope = [tempScope, char(par(1,j-1))];
    end
    tempScope(1) = [];
    factorScope(i) = tempScope;
    
end


for i=1:count
    
    factorSize = size(factorScope(i),2);
    
    tempRow = cell(1,factorSize);
    tempRowIndex = ones(1,factorSize);
    factor = factorScope(i);
    tempNumRows = 1;
    for j=1:factorSize
        tempNodeIndex = mapping(char(factor(1,j)));
        tempNumRows = tempNumRows * size(attributes(tempNodeIndex),2); 
        attr = attributes(tempNodeIndex);
        varName = attr(1,1);
        tempRow(1,j) = varName;
        
    end
    numRows(i) = tempNumRows;
    tempFactorTable = cell(tempNumRows,factorSize);
    tempFactorTable(1,:) = tempRow;
    tempStr = '';
    tempMap = containers.Map('KeyType','char','ValueType','int32');
    for j=1:factorSize
        tempStr = strcat(tempStr,tempRow(1,j));
    end
    tempMap(char(tempStr)) = 1;
    
    for j=2:tempNumRows
        tempStr ='';
        tempRowIndex(1,1) = tempRowIndex(1,1) + 1;
        
        if factorSize==1
            
            tempNodeIndex = mapping(char(factor(1,1)));
            varSize = variableScopeSize(tempNodeIndex);
            attr = attributes(tempNodeIndex);
            tempRow(1,1) = attr(1,tempRowIndex(1,1));
            
        else
        
            for k=2:factorSize

                tempNodeIndex = mapping(char(factor(1,k-1)));
                varSize = variableScopeSize(tempNodeIndex);
                attr = attributes(tempNodeIndex);
                if varSize < tempRowIndex(1,k-1)
                    tempRowIndex(1,k) = tempRowIndex(1,k) + 1;
                    tempRowIndex(1,k-1) = 1;
                    tempRow(1,k-1) = attr(1,1);

                    if k==factorSize
                        tempNodeIndex = mapping(char(factor(1,k)));

                        attr = attributes(tempNodeIndex);

                        tempRow(1,k) = attr(1,tempRowIndex(1,k));

                    end

                else

                    tempRow(1,k-1) = attr(1,tempRowIndex(1,k-1));
                end

               


            end
            
        end
        
        tempFactorTable(j,:) = tempRow; 
        factorSize = size(tempRow,2);
        for k=1:factorSize
             tempStr = strcat(tempStr,tempRow(1,k));
        end
        
        tempMap(char(tempStr)) = j;


    end
   
    factorTable(i) = tempFactorTable;
    factorTableValue(i) = ones(tempNumRows,1);
    factorMap(i) = tempMap;
    featureAvg(i) = zeros(tempNumRows,1);
    featureExp(i) = zeros(tempNumRows,1);
    
end


% expected value from given data


data = importdata('A3-data_2/andes_small.dat');
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



%{
tic
for i=1:dataSize
    
    tempSample = samples(i,:);
    
    for j=1:count
       
        %read sample string 
        factorSize = size(factorScope(j),2);
        
        tempStr = '';
        factScope = factorScope(j);
        tempFactorMap = factorMap(j);
        tempFeatureAvg = featureAvg(j);
        for k=1:factorSize
             varName = factScope(1,k);
             varIndex = mapping(char(varName));
             mapToSample = orderMap(varIndex);
             tempStr = strcat(tempStr,tempSample(1,mapToSample));
        end
        
        tempRow = tempFactorMap(char(tempStr));
        
        tempFeatureAvg(tempRow,1) = tempFeatureAvg(tempRow,1) + 1;
        featureAvg(j) = tempFeatureAvg;
        
    
    end
    
    
    
    
end
toc
%}
%{
tic
for j=1:count
    j
    %read sample string 
    factorSize = size(factorScope(j),2);

    tempStr = '';
    factScope = factorScope(j);
    tempFactorMap = factorMap(j);
    tempFeatureAvg = featureAvg(j);
    
    for i=1:factorSize
        varName = factScope(1,i);
        varIndex = mapping(char(varName));
        factorSampleIndex(1,i) = orderMap(varIndex);
            
    end
        
        
    for i= 1:dataSize

        tempSample = samples(i,:);
        tempStr = '';
        for k=1:factorSize
             tempStr = strcat(tempStr,tempSample(1,factorSampleIndex(1,k)));
        end

        tempRow = tempFactorMap(char(tempStr));
        tempFeatureAvg(tempRow,1) = tempFeatureAvg(tempRow,1) + 1;



    end
    featureAvg(j) = tempFeatureAvg;
        
    end
   
toc
%}


load featureAvgAndes_small.mat
%load featureAvgHepar_small.mat
%load featureAvgInsurance_small.mat
% gibbs sampler
for i=1:count
    
   featureAvg(i) = featureAvg(i) + 1; 
end
% find variable belongs to which factor

for i=1:count
    
   varName = variables(i);
   
   tempNum = [];
   for j=1:count
       
       tempFactor = factorScope(j);
       facSize = size(tempFactor,2);
       
       for k=1:facSize
           if strcmp(varName,tempFactor(1,k))==1
               tempNum = [tempNum,j];
               break;
           end
       end
               
       
   end
   varToFactor(i) = tempNum;
   
    
end

% start generating samples


countIteration = 0;

while countIteration < 10
    countIteration
    
    tempSample = cell(1,count);

    %initialize first sample
    
    for i=1:count

        varIndex = order(i);
        varName  = variables(varIndex);
        varScopeSize = variableScopeSize(varIndex);
        attr = attributes(varIndex);
        randNum = randi(varScopeSize);
        tempSample(1,i) = attr(1,randNum);

    end
    
    expSamplesCount = 1;

    expSamples(expSamplesCount) = tempSample;

    flipI = 1;
    %tempRowIndex = containers.Map('KeyType','char','ValueType','any');
    
    while expSamplesCount < 10000
        %expSamplesCount
        if flipI > count
            flipI = 1;
        end

        varIndex = order(flipI);
        varName = variables(varIndex);
        varScopeSize = variableScopeSize(varIndex);
        attr = attributes(varIndex);
        tempTable = ones(varScopeSize,1);
        tempTable1 = zeros(varScopeSize,1);
        tempFactorIndexes = varToFactor(varIndex);
        numOfFactors = size(tempFactorIndexes,2);

        % tells row of given factor from variable attribute
        tempRowIndex = containers.Map('KeyType','char','ValueType','any');

        for i=1:varScopeSize
            tempRowIndex(char(attr(1,i))) = i;
        end


        
        for i=1:numOfFactors

            tempFactorScope = factorScope(tempFactorIndexes(1,i));
            tempFactorSize = size(tempFactorScope,2);
            tempIndexNum= -1;
            for j=1:tempFactorSize

                if strcmp(varName,tempFactorScope(1,j))==1
                    tempIndexNum = j;
                    break;

                end

            end
            %create value of string from evidence
            %{
            tempStr = '';
            for j=1:tempFactorSize

                if j~=tempIndexNum

                    orderIndex = mapping(char(tempFactorScope(1,j)));
                    orderIndex = orderMap(orderIndex);
                    factorAttrValue = tempSample(1,orderIndex);
                    tempStr = strcat(tempStr,factorAttrValue);

                end

            end
            %}
            % change
            tempFactorMap = factorMap(tempFactorIndexes(1,i));
            tempFactorValue = factorTableValue(tempFactorIndexes(1,i));

            
            for k=1:varScopeSize
                tempStr = '';
                for j=1:tempFactorSize

                    if j~=tempIndexNum

                        orderIndex = mapping(char(tempFactorScope(1,j)));
                        orderIndex = orderMap(orderIndex);
                        factorAttrValue = tempSample(1,orderIndex);
                        tempStr = strcat(tempStr,factorAttrValue);
                    else
                        tempStr = strcat(tempStr,attr(1,k));

                    end

                end
                tempRow = tempFactorMap(char(tempStr));
                tempTable(k,1) = tempTable(k,1) + tempFactorValue(tempRow);
                tempTable1(k,1) = tempTable(k,1)+ log(tempFactorValue(tempRow));
            end
            
            

            % reterive 
            %{
            tempFactorTable = factorTable(tempFactorIndexes(1,i));
            
            numOfRows = size(tempFactorTable,1);
            %'here'
            
            for j=1:numOfRows
                tempStr1 = '';
                rootStr = '';
                for k=1:tempFactorSize

                    if k~=tempIndexNum
                       strValue = tempFactorTable(j,k);
                       tempStr1 = strcat(tempStr1,strValue);

                    else
                        rootStr = tempFactorTable(j,k);

                    end


                end

                if strcmp(tempStr,tempStr1) == 1
                    rowValue = tempRowIndex(char(rootStr));
                    tempTable(rowValue,1) = tempTable(rowValue,1)*tempFactorValue(rowValue);
                end

            end
            %}
            %'here2'
           
        end
      
        
        %tempTable = exp(tempTable1);
        %tempTable = tempTable + max(tempTable);
        %tempTable = max(0,tempTable);
        tempTable1 = exp(tempTable);
        tempSum = 0;
        for j=1:varScopeSize

            tempSum = tempSum + tempTable1(j,1);
        end

        for j=1:varScopeSize
            tempTable1(j,1) = double(tempTable1(j,1))/double(tempSum);
        end



        randNum = rand();

        cumProb = 0.0;
        for j=1:varScopeSize

            cumProb = cumProb + tempTable1(j,1);
            if cumProb > randNum
                tempSample(1,flipI) = attr(1,j);
                break;
            end

        end

        flipI = flipI + 1;


        expSamplesCount = expSamplesCount + 1;
        expSamples(expSamplesCount) = tempSample;
        
    end
    
  
    
    % count expected Value
    dSize = size(expSamples,1);
    
    
    
%{
    for i=1000:dSize

        tempSample = expSamples(i);
        'here'
        tic
        for j=1:count
            
            %read sample string 
            factorSize = size(factorScope(j),2);

            tempStr = '';
            factScope = factorScope(j);
            tempFactorMap = factorMap(j);
            tempFeatureExp = featureExp(j);
            for k=1:factorSize
                 varName = factScope(1,k);
                 varIndex = mapping(char(varName));
                 mapToSample = orderMap(varIndex);
                 tempStr = strcat(tempStr,tempSample(1,mapToSample));
            end

            tempRow = tempFactorMap(char(tempStr));
            tempFeatureExp(tempRow,1) = tempFeatureExp(tempRow,1) + 1;
            featureExp(j) = tempFeatureExp;
            
        end
        toc
        


    end
%}
    
   
    for j=1:count
       
        factorSize = size(factorScope(j),2);

        
        factScope = factorScope(j);
        tempFactorMap = factorMap(j);
        tempFeatureExp = zeros(numRows(j),1);
        factorSampleIndex = zeros(1,factorSize);
        
        for i=1:factorSize
            varName = factScope(1,i);
            varIndex = mapping(char(varName));
            factorSampleIndex(1,i) = orderMap(varIndex);
            
        end
        
        
        for i= 1000:dSize
            
            tempSample = expSamples(i);
            tempStr = '';
            for k=1:factorSize
                 tempStr = strcat(tempStr,tempSample(1,factorSampleIndex(1,k)));
            end

            tempRow = tempFactorMap(char(tempStr));
            tempFeatureExp(tempRow,1) = tempFeatureExp(tempRow,1) + 1;
            
        
        
        end
        featureExp(j) = tempFeatureExp;
        featureExp(j) = featureExp(j) + 1;
    end
   

    mAvg = 100000;
    nExp = 9000;
    count = size(variables,1);
    C = 1.0;
    %update table values
    %factorTableValue(8)
    for i=1:count
        %factorTableValue(i)
        %featureAvg(i)/mAvg
        %featureExp(i)/nExp
        factorTableValue(i) = factorTableValue(i) + (((featureAvg(i) / mAvg)  - (featureExp(i) / nExp)) - (C*factorTableValue(i)/mAvg));   
        
    end
    
    %factorTableValue(2)
    
    countIteration = countIteration  + 1;

end



% print potentials to .txt file


for i=1:count
    
    fprintf(out_file,'probability ( ');
    ttFactorScope = factorScope(i);
    for j=1:size(factorScope(i),2)-1
        fprintf(out_file,'%s, ',ttFactorScope{1,j});
        
    end
    fprintf(out_file,'%s ) { \n',ttFactorScope{1,size(factorScope(i),2)});
    
    ttFactorTable = factorTable(i);
    ttFactorTableValue = factorTableValue(i);
    
    ttFactorSize = size(ttFactorTableValue,1);
    ttFactorSizeCol = size(ttFactorTable,2);
    for j=1:ttFactorSize
        fprintf(out_file,'( ');
        for k=1:ttFactorSizeCol-1
            fprintf(out_file,'%s, ', ttFactorTable{j,k});
        end
        
        fprintf(out_file,'%s ) %f\n', ttFactorTable{j,ttFactorSizeCol}, exp(ttFactorTableValue(j)));
        
        
    end
    
    fprintf(out_file,'\n}\n');
    
end
%}


%predicting

countChar = 0;
totalChar = 0;
testData = importdata('andes_test.dat');
truthData = importdata('andes_TrueValues.dat');
testSize = size(testData,1);

testSize = testSize - 1;

count = size(variables,1);

testExamples =  cell(testSize,count);
truthExamples = cell(testSize,count);

for i=2:11
    i
    tempExample1 = testData{i};
    tempExample = strsplit(tempExample1);
    testExamples(i-1,:) = tempExample;
    
    tempExample1 = truthData{i};
    tempExample = strsplit(tempExample1);
    truthExamples(i-1,:) = tempExample; 
    
    
end

for i=2:11
    
    visitedArray = strcmp(testExamples(i-1,:), '?');
    % 1 means ?
    
    testSampleGen = cell(10000,count);
    
    % initialize
    tempTestExample = testExamples(i-1,:);
    for j=1:count
        
        if visitedArray(1,j)==1
            
            tempTestActualIndex = order(j);
            tempTestScopeSize = variableScopeSize(tempTestActualIndex);
            tempTestAttr = attributes(tempTestActualIndex);
            tempRand = randi(tempTestScopeSize);
            tempTestExample(1,j) = tempTestAttr(1,tempRand);
            
        end
        
        
    end
    
    testSampleGen(1,:) = tempTestExample;
    
    tempCount = 1;
    
    
    for j=2:10000
        
        if tempCount > count
            tempCount = 1;
        end
        
        
        if visitedArray(1,tempCount)==0
            while visitedArray(1,tempCount)==0
                tempCount = tempCount + 1;
                if tempCount > count
                    tempCount = 1;
                end
            end
        end
               
        % ready to sample
        lastSample = testSampleGen(j-1,:);
        tempTestActualIndex = order(tempCount);
        tempTestVar = variables(tempTestActualIndex);
        tempTestScopeSize = variableScopeSize(tempTestActualIndex);
        tempTestAttr = attributes(tempTestActualIndex);
        tempTestTable = ones(tempTestScopeSize,1);
        
        tempTestFactors = varToFactor(tempTestActualIndex);
        tempTestFactorSize = size(tempTestFactors,2);
        
        for k=1:tempTestFactorSize
            
            tempTestFactorScope = factorScope(tempTestFactors(1,k));
            tempTestFactorScopeSize = size(tempTestFactorScope,2);
            tempTestIndex = -1;
            for l = 1:tempTestFactorScopeSize
                if strcmp(tempTestVar, tempTestFactorScope(1,l))==1
                    
                    tempTestIndex = l;
                    break;
                end
            end
            tempTestFactorMap = factorMap(tempTestFactors(1,k));
            tempTestFactorValue = factorTableValue(tempTestFactors(1,k));
            
            for l=1:tempTestScopeSize
                tempStr ='';
                for o=1:tempTestFactorScopeSize
                    
                    if o ~= tempTestIndex
                        tempTest1 = mapping(char(tempTestFactorScope(1,o)));
                        tempTestSample1 = orderMap(tempTest1);
                        tempTestSampleValue = lastSample(1,tempTestSample1);
                        tempStr = strcat(tempStr,tempTestSampleValue);
                        
                    else
                        
                        tempStr = strcat(tempStr, tempTestAttr(1,l));
                    end
                    
                end
                
                tempTestRow = tempTestFactorMap(char(tempStr));
                tempTestValue1 = tempTestFactorValue(tempTestRow);
                tempTestTable(l,1) = tempTestTable(l,1) + tempTestValue1;
                
            end
        
        end
        
        tempTestTable1 = exp(tempTestTable);
        tempTestTableSum = sum(tempTestTable1);
        tempTestTable1 = double(tempTestTable1)/double(tempTestTableSum);
        cum = 0.0;
        
        tempR = rand;
        
        
        for k=1:tempTestScopeSize
            cum = cum + tempTestTable1(k,1);
            if cum >= tempR
                lastSample(1,tempCount) = tempTestAttr(1,k);
               
                tempCount = tempCount + 1;
                break;
            end
     
        end
        
        testSampleGen(j,:) = lastSample;
        
    end
    'here'
    
    for j=1:count

        if visitedArray(1,j)==1
            
            tempTestActual1 = order(j);
            tempTestActualName = variables(tempTestActual1);
            tempTestActual1Size = variableScopeSize(tempTestActual1);
            tempTestCount = zeros(tempTestActual1Size,1);
            tempTestActualAttr = attributes(tempTestActual1);
            
            mapElements = containers.Map('KeyType','char','ValueType','any');
            for k=1:tempTestActual1Size
                
                mapElements(char(tempTestActualAttr(1,k))) = k;
                
            end
            
            for k=1001:9999
                tempSampleValue = testSampleGen(k,j);
                tempSampleRow1 = mapElements(char(tempSampleValue));
                tempTestCount(tempSampleRow1,1) = tempTestCount(tempSampleRow1) + 1;
                
            end
            
            [x11,y11] = max(tempTestCount);
            sumTestCount = sum(tempTestCount);
            tempTestCount = double(tempTestCount)/ double(sumTestCount);
            %printing
            fprintf(out_file1,'%s\n',tempTestActualAttr{1,y11});
            fprintf(out_file1,'%s ',tempTestActualName);
            
            for ll=1:tempTestActual1Size
                
                fprintf(out_file1,'%s:%f ',tempTestActualAttr{1,ll},tempTestCount(ll,1));
                
            end
            fprintf(out_file1,'\n');
            
            %update DLL
           
            
            truthValue11 = truthExamples(i-1,j);
            truthIndex11 = mapElements(char(truthValue11));
            if tempTestCount(truthIndex11,1)>0
                DLL = DLL + log(tempTestCount(truthIndex11,1));
            end
            if y11==truthIndex11
                countChar = countChar + 1
            end
               
            totalChar = totalChar + 1;
        end
    end
    fprintf(out_file1,'\n');
           
    countChar/totalChar
    
end
DLL/10


