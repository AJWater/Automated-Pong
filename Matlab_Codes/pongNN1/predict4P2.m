function p = predict4P2(initial_weight, X)
%PREDICT Predict the label of an input given a trained neural network
%   p = PREDICT(Theta1, Theta2, X) outputs the predicted label of X given the
%   trained weights of a neural network (Theta1, Theta2)

% Useful values
m = size(X, 1);


h{1,size(initial_weight,2)} = [];

%num_labels = size(Theta5, 1);

% You need to return the following variables correctly 
p = zeros(size(X, 1), 1);
                %1x10                  10x12
h{1} = sigmoid([ones(m, 1) X] * initial_weight{1}');
for i = 2:size(initial_weight,2)
    h{i} = sigmoid([ones(m, 1) h{i-1}] * initial_weight{i}'); 
    
%h2 = sigmoid([ones(m, 1) h1] * Theta2');
%h3 = sigmoid([ones(m, 1) h2] * Theta3');
%h4 = sigmoid([ones(m, 1) h3] * Theta4');
%h5 = sigmoid([ones(m, 1) h4] * Theta5');
[dummy, p] = max( h{size(initial_weight,2)}, [], 2);

% =========================================================================


end