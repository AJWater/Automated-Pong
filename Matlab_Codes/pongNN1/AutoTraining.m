 load('speed_scores');
 load('Parameters');
 load('ParameterGenerator');
 load('score_records');
% 
% %Initial random selection of parameters
% 
for i = 7
    %i = 1;
    if i == 1  
        for j = 69 %Choose number of random groups of parameters to initialize and test
            [OutputData, params] = AutoPong2v2Initiation(j);
            if OutputData(1,3) ~= 2 %Makes sure the paddle is moving both left and right
                OutputData(1,1) = 0;
            end    
            speed_scores = [speed_scores ; OutputData];
            save('speed_scores.mat', 'speed_scores');

            Parameters(j) = {params};
            save('Parameters.mat', 'Parameters');
        end
    else
        for j = 1:50
            disp(j)
            [OutputData, params] = AutoPong2v2no2(ParameterGenerator{j},j);
            if OutputData(1,3) ~= 2 %Makes sure the paddle is moving both left and right
                OutputData(1,1) = 0;
            end
            
            
            
            speed_scores = [speed_scores ; OutputData];
            save('speed_scores.mat', 'speed_scores');

            Parameters(j) = {params};
            save('Parameters.mat', 'Parameters');
        end   
    end
    score_records(i) = {speed_scores};
    save('score_records.mat', 'score_records');
    
    %%
    % %Order the speed_scores by the first column showing the number of training
    % %points from largest to smallest
    % 
     max_min_rows = flipud(sortrows(speed_scores,1)); 
     best_seed_values = [max_min_rows(1:2,2)];
    % 
    % %Get parameters of best performing 2 rows
    % 
     for j = 1:2
         ParameterGenerator(j) = {Parameters{best_seed_values(j)}};
     end
    % 
    % %Use best parameters to generate 48 new random parameter groups

    ParamVectorLength = length(ParameterGenerator{1});

    for j = 3:50
        MixedParam = [];
        a = ParameterGenerator{1};
        b = ParameterGenerator{2};
        for k = 1:ParamVectorLength
            x = randi(3);
            if x == 1
                MixedParam(k,1) = a(k);
            elseif x == 2
                MixedParam(k,1) = b(k);
            else
                MixedParam(k,1) = rand;
            end
        end
        ParameterGenerator(j) = {MixedParam};
    end    

    save('ParameterGenerator.mat', 'ParameterGenerator');
    speed_scores(:) = [];
    save('speed_scores.mat', 'speed_scores');
end













