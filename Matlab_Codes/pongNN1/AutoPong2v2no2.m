%+-------------------------------------------------------+%
%|                DAVE'S MATLAB PONG v0.3                |%
%|                  by David Buckingham                  |%
%|                                                       |%
%| a fast-paced two-player game inspired by Atari's Pong |%
%+-------------------------------------------------------+%

% v0.3
% fixed bug where ball bouncing off right or left wall caused goal.
% paddle height reduced.
% ball acceleration reduced.
% changed colors and aesthetics.
% increased winning score to 5.
% main figure is wider and less tall. no change to plot dimensions.
% 
% v0.2
% fixed bug where ball gets 'stuck' along top or bottom wall.
% 
% 
% around line 280 for invisible wall

function [speed_scores, Params] = AutoPong2v2no2(TrainingParams, seed_value)

    close all
    %clear all
    clc

    %----------------------CONSTANTS----------------------
    %game settings
    MAX_POINTS = 3;
    START_DELAY = 1;

    %movemment
    FRAME_DELAY = .003; %animation frame duration in seconds, .01 is good.
    speed_factor = 2;
    MIN_BALL_SPEED = .8*speed_factor; %each round ball starts at this speed
    MAX_BALL_SPEED = 3*speed_factor; %wont accelerate past this, dont set too high or bugs.
    BALL_ACCELERATION = 0.02; %how much ball accelerates each bounce.
    PADDLE_SPEED = 1.3;
    %B_FACTOR and P_FACTOR increase the ball's dx/dy, i.e. making it move
    %more horizontaly and less vertically. When the ball bounces, B_FACTOR
    %is used to calculate a random variance in the resulting ball vector.
    %Lower values increases dx/dy. 1 seems to work well for B_FACTOR. When the
    %ball hits a paddle, its new vector is the line connecting the center of
    %the paddle to the center of the ball. x value of this vector is multiplied
    %P_FACTOR. Higher P_FACTOR increases the ball's dx/dy after hitting
    %a paddle. 2 seems to work well for P_FACTOR.
    B_FACTOR = 1;
    P_FACTOR = 2;
    %Y_FACTOR is used to fix a bug where ball would get 'stuck' bouncing
    %back and forth along the top or bottom wall. A collision with top or
    %bottom wall causes a bounce where new dx is -(old dx). If old dx is 0 then
    %new dx is 0 so ball never leaves wall. Y_FACTOR is added to dx when
    %ball bounces off top or bottom wall. It should be small. 0.01 works well.
    Y_FACTOR = 0.01;
    %GOAL_BUFFER is distance beyond end of plot ball must travel to score a
    %goal. if this is 0 or too small, goals can be scored by fast ball bouncing
    %off right or left wall. Too high and angled goals will bounce back in
    GOAL_BUFFER = 5;

    %layout/structure
    BALL_RADIUS = 1.5; %radius to calculate bouncing
    WALL_WIDTH = 3;
    FIGURE_WIDTH = 800; %pixels
    FIGURE_HEIGHT = 800;
    PLOT_W = 150; %width in plot units. this will be main units for program
    PLOT_H = 150; %height
    GOAL_SIZE = 50;
    LR_GOAL_TOP = (PLOT_H+GOAL_SIZE)/2;
    LR_GOAL_BOT = (PLOT_H-GOAL_SIZE)/2;
    TB_GOAL_Right = (PLOT_W+GOAL_SIZE)/2;
    TB_GOAL_Left = (PLOT_W-GOAL_SIZE)/2;
    PADDLE_H = 18; %height
    PADDLE_W = 3; %width
    LR_PADDLE = [0 PADDLE_W PADDLE_W 0 0; PADDLE_H PADDLE_H 0 0 PADDLE_H];
    TB_PADDLE = flipud(LR_PADDLE);
    PADDLE_SPACE = 10; %space between paddle and goal

    %appearance
    FIGURE_COLOR = [0, 0, 0]; %program background
    AXIS_COLOR = [.15, .15, .15]; %the court
    CENTER_RADIUS = 15; %radius of circle in center of court.
    BALL_MARKER_SIZE = 10; %aesthetic, does not affect physics, see BALL_RADIUS
    BALL_COLOR = [.1, .7, .1];
    BALL_OUTLINE = [.7, 1, .7];
    BALL_SHAPE = 'o';
    PADDLE_LINE_WIDTH = 2;
    WALL_COLOR = [.3, .3, .8]; %format string for drawing walls
    PADDLE_COLOR = [1, .5, 0];
    CENTERLINE_COLOR = PADDLE_COLOR .* .8; %format string for centerline
    PAUSE_BACKGROUND_COLOR = FIGURE_COLOR;
    PAUSE_TEXT_COLOR = [.9, .9, .9];
    PAUSE_EDGE_COLOR = BALL_COLOR;
    TITLE_COLOR = 'w';

    %messages
    PAUSE_WIDTH = 36; %min pause message width, DO NOT MODIFY, KEEP AT 36
    MESSAGE_X = 62; %location of message displays. 38, 55 is pretty centered
    MESSAGE_Y = 65;
    MESSAGE_PAUSED = ['             GAME PAUSED' 10 10];
    MESSAGE_INTRO = [...
      '             welcome to ' 10 10 ...
      '         DAVE' 39 'S MATLAB PONG' 10 10 ...
      '     first to get ' num2str(MAX_POINTS) ' points wins!' 10 10 ...
      '    player 1:           player 2:' 10 ...
      ' use (w)(a)(s)(d)     use arrow keys' 10 10 ...
      ];
    MESSAGE_CONTROLS = '  pause:(p)   reset:(r)   quit:(q)';

    %----------------------VARIABLES----------------------
    fig = []; %main program figure
    quitGame = false; %guard for main loop. when true, program ends
    paused = []; %true if game is paused
    score = []; %1x2 vector holding player scores
    winner = []; %normally 0. 1 if player1 wins, 2 if player2 wins
    ballPlot = []; %main plot, includes ball and walls
    paddle1Plot = []; %plot for paddle
    paddle2Plot = [];
    paddle3Plot = []; 
    paddle4Plot = [];
    ballVector=[]; %normalized vector for ball movement
    ballSpeed=[];
    ballX = []; %ball location
    ballY = [];
    paddle1V = []; %holds either 0, -1, or 1 for paddle movement
    paddle2V = [];
    paddle3V = []; 
    paddle4V = [];
    paddle1 = []; %2x5 matrix describing paddle, based on PADDLE
    paddle2 = [];
    paddle3 = [];
    paddle4 = [];
    paddle_Pos = [];

    %-----------------------SUBROUTINES----------------------

    %------------createFigure------------
    %sets up main program figure
    %plots ball, walls, paddles
    %called once at start of program
      function createFigure
        %ScreenSize is a four-element vector: [left, bottom, width, height]:
        scrsz = get(0,'ScreenSize');
        fig = figure('Position',[(scrsz(3)-FIGURE_WIDTH)/2 ...
          (scrsz(4)-FIGURE_HEIGHT)/2 ...
          FIGURE_WIDTH, FIGURE_HEIGHT]);
        %register keydown and keyup listeners
        set(fig,'KeyPressFcn',@keyDown, 'KeyReleaseFcn', @keyUp);
        %figure can't be resized
        set(fig, 'Resize', 'off');
        axis([0 PLOT_W 0 PLOT_H]);
        axis manual;
        %set color for the court, hide axis ticks.
        set(gca, 'color', AXIS_COLOR, 'YTick', [], 'XTick', []);
        %set background color for figure
        set(fig, 'color', FIGURE_COLOR);
        hold on;
        %plot walls
            %Top left walls
        TL_WallXs = [0,0,TB_GOAL_Left];
        TL_WallYs = [LR_GOAL_TOP,PLOT_H,PLOT_H];
            %Top right walls
        TR_WallXs = [TB_GOAL_Right,PLOT_W,PLOT_W];
        TR_WallYs = [PLOT_H,PLOT_H,LR_GOAL_TOP];
            %Bottom right walls
        BR_WallXs = [PLOT_W,PLOT_W,TB_GOAL_Right];
        BR_WallYs = [LR_GOAL_BOT,0,0];
            %Bottom Left walls
        BL_WallXs = [0,0,TB_GOAL_Left];
        BL_WallYs = [LR_GOAL_BOT,0,0];
        plot(TL_WallXs, TL_WallYs, '-', ...
          'LineWidth', WALL_WIDTH, 'Color', WALL_COLOR);
        plot(TR_WallXs, TR_WallYs, '-', ...
          'LineWidth', WALL_WIDTH, 'Color', WALL_COLOR);
        plot(BR_WallXs, BR_WallYs, '-', ...
          'LineWidth', WALL_WIDTH, 'Color', WALL_COLOR);
        plot(BL_WallXs, BL_WallYs, '-', ...
          'LineWidth', WALL_WIDTH, 'Color', WALL_COLOR);
        %calculate circle to draw on court
        thetas = linspace(0, (2*pi), 100);
        circleXs = (CENTER_RADIUS .* cos(thetas)) + (PLOT_W / 2);
        circleYs = (CENTER_RADIUS .* sin(thetas))+ (PLOT_H / 2);
        %draw lines on court
        centerline = plot([PLOT_W/2, PLOT_W/2],[PLOT_H, 0],'--');
        set(centerline, 'Color', CENTERLINE_COLOR);
        centerCircle = plot(circleXs, circleYs,'--');
        set(centerCircle, 'Color', CENTERLINE_COLOR);

        %plot ball, we'll set ball location in refreshPlot
        ballPlot = plot(0,0);
        set(ballPlot, 'Marker', BALL_SHAPE);
        set(ballPlot, 'MarkerEdgeColor', BALL_OUTLINE);
        set(ballPlot, 'MarkerFaceColor', BALL_COLOR);
        set(ballPlot, 'MarkerSize', BALL_MARKER_SIZE);
        %plot paddles, we'll set paddle locations in refreshPlot
        paddle1Plot = plot(0,0, '-', 'LineWidth', PADDLE_LINE_WIDTH);
        paddle2Plot = plot(0,0, '-', 'LineWidth', PADDLE_LINE_WIDTH);
        paddle3Plot = plot(0,0, '-', 'LineWidth', PADDLE_LINE_WIDTH);
        paddle4Plot = plot(0,0, '-', 'LineWidth', PADDLE_LINE_WIDTH);
        set(paddle1Plot, 'Color', PADDLE_COLOR);
        set(paddle2Plot, 'Color', PADDLE_COLOR);
        set(paddle3Plot, 'Color', PADDLE_COLOR);
        set(paddle4Plot, 'Color', PADDLE_COLOR);

      end

    %------------newGame------------
    %resets game to starting conditions.
    %called from main loop at program start
    %called from keydown when user hits 'r'
    %called from checkGoal after someone wins
    %sets some variables, calls reset game,
    %and calls pauseGame with intro message
      function newGame
        winner = 0;
        score = [0, 0];
        paddle1V = 0; %velocity
        paddle2V = 0; %velocity
        paddle3V = 0; %velocity
        paddle4V = 0; %velocity

        %Left paddle
        paddle1 = [LR_PADDLE(1,:)+PADDLE_SPACE; ...
          LR_PADDLE(2,:)+((PLOT_H - PADDLE_H)/2)];

        %Top paddle
        paddle2 = [TB_PADDLE(1,:)+((PLOT_H-PADDLE_H)/2); ...
          TB_PADDLE(2,:)+PLOT_H-PADDLE_SPACE-PADDLE_W];

        %Right paddle
        paddle3 = [LR_PADDLE(1,:)+ PLOT_W - PADDLE_SPACE - PADDLE_W; ...
          LR_PADDLE(2,:)+((PLOT_H - PADDLE_H)/2)];

        %Bottom paddle
        paddle4 = [TB_PADDLE(1,:) + ((PLOT_H-PADDLE_H)/2); ...
          TB_PADDLE(2,:) + PADDLE_SPACE];
        resetGame;
        if ~quitGame; %incase we try to quit from winner message
         % pauseGame([MESSAGE_INTRO, MESSAGE_CONTROLS]);
        end
      end

    %------------resetGame------------
    %resets ball location speed and direction
    %resets title string to display scores
    %called from newGame
    %called from checkGoal after each goal
      function resetGame
        bounce([1-(2*rand), 1-(2*rand)]);
        ballSpeed=MIN_BALL_SPEED;
         ballX = PLOT_W/2;
         ballY = PLOT_H/2;
        %here 19 is the space between the scores
        titleStr = sprintf('%d / %d%19d / %d', ...
          score(1), MAX_POINTS, score(2), MAX_POINTS);
        t = title(titleStr, 'Color', TITLE_COLOR);
        set(t, 'FontName', 'Courier','FontSize', 15, 'FontWeight', 'Bold');
        refreshPlot;
        if ~quitGame; %make sure we don't wait to quit if user hits 'q'
          pause(START_DELAY);
        end
      end

    %------------moveBall------------
    %calculates new ball location
    %checks if it will hit any walls or paddles
    %if it does, call bounce to change ball vector
    %move ball to new location
    %called from main loop on every frame
      function moveBall

        %paddle boundaries, useful for hit testing ball
        p1T = paddle1(2,1); % Y coordinate of top of paddle 1
        p1B = paddle1(2,3); % Y coordinate of bottom of paddle 1
        p1L = paddle1(1,1); % X coordinate of left of paddle 1
        p1R = paddle1(1,2); % X coordinate of right of paddle 1
        p1Center = ([p1L p1B] + [p1R p1T]) ./ 2;    % [x,y] of paddle 1 center
        p2T = paddle2(2,3); 
        p2B = paddle2(2,1);
        p2L = paddle2(1,3);
        p2R = paddle2(1,1);
        p2Center = ([p2L p2B] + [p2R p2T]) ./ 2;
        p3T = paddle3(2,1);
        p3B = paddle3(2,3);
        p3L = paddle3(1,1);
        p3R = paddle3(1,2);
        p3Center = ([p3L p3B] + [p3R p3T]) ./ 2;
        p4T = paddle4(2,3);
        p4B = paddle4(2,1);
        p4L = paddle4(1,3);
        p4R = paddle4(1,1);
        p4Center = ([p4L p4B] + [p4R p4T]) ./ 2;
        paddle_Pos = [p1Center(2), p2Center(1), p3Center(2), p4Center(1)];

        %while hit %calculate new vectors until we know it wont hit something
        %temporary new ball location, only apply if ball doesn't hit anything.
        newX = ballX + (ballSpeed * ballVector(1));
        newY = ballY + (ballSpeed * ballVector(2));

        %hit test right wall
         if (newX > (PLOT_W - BALL_RADIUS) ...
             && (ballY< (LR_GOAL_BOT+BALL_RADIUS) || newY> (LR_GOAL_TOP-BALL_RADIUS)))
           %hit right wall
           if (newY > LR_GOAL_BOT && newY < (LR_GOAL_BOT + BALL_RADIUS))
             %hit bottom goal edge
             bounce([(newX - PLOT_W), (newY - LR_GOAL_BOT)]);
           elseif (newY < LR_GOAL_TOP && newY > (LR_GOAL_TOP - BALL_RADIUS))
             %hit top goal edge
             bounce([(newX - PLOT_W), (newY - LR_GOAL_TOP)]);
           else
             %hit flat part of right wall
             bounce([-1 * abs(ballVector(1)), ballVector(2)]);
           end

         %hit test left wall
        elseif (newX < BALL_RADIUS ...
            && (newY < (LR_GOAL_BOT+BALL_RADIUS) || newY > (LR_GOAL_TOP-BALL_RADIUS)))
          %hit left wall
          if (newY > LR_GOAL_BOT && newY < (LR_GOAL_BOT + BALL_RADIUS))
            %hit bottom goal edge
            bounce([newX, (newY - LR_GOAL_BOT)]);
          elseif (newY < LR_GOAL_TOP && newY > (LR_GOAL_TOP - BALL_RADIUS))
            %hit top goal edge
            bounce([newX, (newY - LR_GOAL_TOP)]);
          else
            bounce([abs(ballVector(1)), ballVector(2)]);
          end

            %hit test top wall
         elseif (newY > (PLOT_H - BALL_RADIUS) ...
             && (ballX < (TB_GOAL_Left+BALL_RADIUS) || newX > (TB_GOAL_Right-BALL_RADIUS)))
           %hit top wall
           if (newX > TB_GOAL_Left && newX < (TB_GOAL_Left + BALL_RADIUS))
             %hit left goal edge
             bounce([(newX - TB_GOAL_Left), (newY - PLOT_H)]);
           elseif (newX < TB_GOAL_Right && newX > (TB_GOAL_Right - BALL_RADIUS))
             %hit right goal edge
             bounce([(newX - TB_GOAL_Right), (newY - PLOT_H)]);
           else
             %hit flat part of top wall
             bounce([ballVector(1), -1 * abs(ballVector(2))]);
           end

            %hit test bottom wall
          elseif (newY < BALL_RADIUS) ...
             && (ballX < (TB_GOAL_Left+BALL_RADIUS) || newX > (TB_GOAL_Right-BALL_RADIUS))
           %hit bottom wall
           if (newX > TB_GOAL_Left && newX < (TB_GOAL_Left + BALL_RADIUS))
             %hit left goal edge
             bounce([(newX - TB_GOAL_Left), newY]);
           elseif (newX < TB_GOAL_Right && newX > (TB_GOAL_Right - BALL_RADIUS))
             %hit right goal edge
             bounce([(newX - TB_GOAL_Right), newY]);
           else
             %hit flat part of right wall
             bounce([ballVector(1), abs(ballVector(2))]);
           end


        % hit test right invisible wall
        elseif (newX > 149)
             bounce([-1 * abs(ballVector(1)), ballVector(2)]);

        %hit test left invisible wall
        elseif (newX < 1)          % Modify this number for position 
            bounce([abs(ballVector(1)), ballVector(2)]); % of invisble wall

        %hit test top invisible wall
        elseif (newY > 149)
            bounce([ballVector(1), -1 * abs(ballVector(2))]);

        %hit test bottom invisible wall
     %   elseif (newY < 1)
     %       bounce([ballVector(1), abs(ballVector(2))]);

          %hit test paddle 1
        elseif (newX < p1R + BALL_RADIUS ...
            && newX > p1L - BALL_RADIUS ...
            && newY < p1T + BALL_RADIUS ...
            && newY > p1B - BALL_RADIUS)
          bounce([(ballX-p1Center(1)) * P_FACTOR, newY-p1Center(2)]);

          %hit test paddle 2
        elseif (newX < p2R + BALL_RADIUS ...
            && newX > p2L - BALL_RADIUS ...
            && newY < p2T + BALL_RADIUS ...
            && newY > p2B - BALL_RADIUS)
          bounce([(ballX-p2Center(1)) * P_FACTOR, newY-p2Center(2)]);

          %hit test paddle 3
         elseif (newX < p3R + BALL_RADIUS ...
            && newX > p3L - BALL_RADIUS ...
            && newY < p3T + BALL_RADIUS ...
            && newY > p3B - BALL_RADIUS)
          bounce([(ballX-p3Center(1)), (newY-p3Center(2)) * P_FACTOR]);

          %hit test paddle 4
         elseif (newX < p4R + BALL_RADIUS ...
            && newX > p4L - BALL_RADIUS ...
            && newY < p4T + BALL_RADIUS ...
            && newY > p4B - BALL_RADIUS)
          bounce([(ballX-p4Center(1)), (newY-p4Center(2)) * P_FACTOR]);
          if newY > p4T 
              TrainingPoints = TrainingPoints +1;
              if newX < TB_GOAL_Right && newX > TB_GOAL_Left
                  TrainingPoints = TrainingPoints +1;
              end    
          end    

        else
          %no hits
        end

        %move ball to new location
        ballX = newX;
        ballY = newY;

      end

    %------------movePaddles------------
    %uses paddle velocity set paddles
    %called from main loop on every frame
        function movePaddles
        %set new paddle locations
        paddle1(2,:) = paddle1(2,:) + (PADDLE_SPEED * paddle1V);
        paddle3(2,:) = paddle3(2,:) + (PADDLE_SPEED * paddle3V);
        paddle2(1,:) = paddle2(1,:) + (PADDLE_SPEED * paddle2V);
        paddle4(1,:) = paddle4(1,:) + (PADDLE_SPEED * paddle4V);
        %if paddle out of bounds, move it in bounds
        if paddle1(2,1) > PLOT_H
          paddle1(2,:) = LR_PADDLE(2,:) + PLOT_H - PADDLE_H;
        elseif paddle1(2,3) < 0
          paddle1(2,:) = LR_PADDLE(2,:);
        end
        if paddle3(2,1) > PLOT_H
          paddle3(2,:) = LR_PADDLE(2,:) + PLOT_H - PADDLE_H;
        elseif paddle3(2,3) < 0
          paddle3(2,:) = LR_PADDLE(2,:);
        end
        if paddle2(1,2) > PLOT_W
          paddle2(1,:) = TB_PADDLE(1,:) + PLOT_W - PADDLE_H;
        elseif paddle2(1,3) < 0
          paddle2(1,:) = TB_PADDLE(1,:);
        end
        if paddle4(1,2) > PLOT_W
          paddle4(1,:) = TB_PADDLE(1,:) + PLOT_W - PADDLE_H;
        elseif paddle4(1,3) < 0
          paddle4(1,:) = TB_PADDLE(1,:);
        end

      end

    %------------refreshPlot------------
    %sets data in plots
    %calls matlab's drawnow to refresh plots
    %uses matlab pause to create animation frame
    %called from main loop on every frame
      function refreshPlot
        set(ballPlot, 'Xdata', ballX, 'YData', ballY);
        set(paddle1Plot, 'Xdata', paddle1(1,:), 'YData', paddle1(2,:));
        set(paddle2Plot, 'Xdata', paddle2(1,:), 'YData', paddle2(2,:));
        set(paddle3Plot, 'Xdata', paddle3(1,:), 'YData', paddle3(2,:));
        set(paddle4Plot, 'Xdata', paddle4(1,:), 'YData', paddle4(2,:));
        drawnow;
        pause(FRAME_DELAY);
      end

    %------------checkGoal------------
    %check ballX to see if ball passed through goal
    %update score and see if anybody won
    %call resetGame to reset ball location etc.
    %if somebody won, then
    %call pauseGame to display message, call newGame
    %called from main loop on every frame
      function checkGoal
        goal = false;

        if ballX > (PLOT_W + BALL_RADIUS + GOAL_BUFFER)
          score(1) = score(1) + 1;
          if score(1) == MAX_POINTS;
            winner = 1;
          end
          goal = true;
        elseif ballX < (0 - BALL_RADIUS - GOAL_BUFFER)
          score(2) = score(2) + 1;
          if score(2) == MAX_POINTS;
            winner = 2;
          end
          goal = true;
        elseif ballY > (PLOT_H + BALL_RADIUS + GOAL_BUFFER)
            score(1) = score(1) + 1;
            if score(1) == MAX_POINTS;
            winner = 1;
            end
            goal = true;
        elseif ballY < (0 - BALL_RADIUS - GOAL_BUFFER) 
            score(2) = score(2) + 1;
          if score(2) == MAX_POINTS;
            winner = 2;
          end
          goal = true;

        end

        if goal %a goal was made
          pause(START_DELAY);
          resetGame;
          if winner > 0 %somebody won
           % pauseGame(['      PLAYER ' num2str(winner) ' IS THE WINNER!!!' 10])
          %  newGame;
          quitGame = true;
          else %nobody won
          end
        end
      end

    %------------pauseGame------------
    %%sets paused variable to true
    %starts a while loop guarded by pause variable
    %displays provided string message
    %called from newGame at game start
    %called from keyDown when user hits 'p'
    %called from checkGoal when someone scores
      function pauseGame(input)
        paused = true;
        str = '      hit any key to continue...';
        spacer = 1:PAUSE_WIDTH;
        spacer(:) = uint8(' ');
        while paused
          printText = [spacer 10 input 10 str 10];
          h = text(MESSAGE_X,MESSAGE_Y,printText);
          set(h, 'BackgroundColor', PAUSE_BACKGROUND_COLOR)
          set(h, 'Color', PAUSE_TEXT_COLOR)
          set(h,'EdgeColor',PAUSE_EDGE_COLOR);
          set(h, 'FontSize',5,'FontName','Courier','LineStyle','-','LineWidth',1);
          pause(FRAME_DELAY)
          delete(h);
        end
      end

    %------------unpauseGame------------
    %sets paused to false
    %called from keyDown when user hits any key
      function unpauseGame()
        paused = false;
      end

    %------------bounce------------
    %takes input vector as argument
    %increases dx/dy for more horizontal movement
    %normalizes vector sets as new ball vector
    %accelerates ball
    %called by moveBall whenever ball hits something
      function bounce (tempV)
        %increase dx by a random amount
        %helps keep the ball moving more horizontally than vertically.
        %tempV(1) = tempV(1) * ((rand/B_FACTOR) + 1);
        %normalize vector
        tempV = tempV ./ (sqrt(tempV(1)^2 + tempV(2)^2));
        ballVector = tempV;
        %just to make things interesting, bouncing accelerates ball
        if (ballSpeed + BALL_ACCELERATION < MAX_BALL_SPEED)
          ballSpeed = ballSpeed + BALL_ACCELERATION;
        end
      end



    %------------keyDown------------
    %listener registered in createFigure
    %listens for input
    %sets appropriate variables and calls functions
      function keyDown(src,event)
        switch event.Key
          case 'w'
            paddle1V = 1;
          case 's'
            paddle1V = -1;
     %     case 'a'
     %       paddle4V = -1;
     %     case 'd'
     %       paddle4V = 1;

          case 'rightarrow'
            paddle2V = 1;
          case 'leftarrow'
            paddle2V = -1;
          case 'uparrow'
            paddle3V = 1;
          case 'downarrow'
            paddle3V = -1;

          case 'p'
            if ~paused
              pauseGame([MESSAGE_PAUSED MESSAGE_CONTROLS]);
            end
          case 'r'
            newGame;
          case 'q'
            unpauseGame;
            quitGame = true;
        end
        unpauseGame;
      end

    %------------keyUp------------
    %listener registered in createFigure
    %used to stop paddles on keyup
      function keyUp(src,event)
        switch event.Key
          case 'w'
            if paddle1V == 1
              paddle1V = 0;
            end
          case 's'
            if paddle1V == -1
              paddle1V = 0;
            end
     %     case 'a'
     %       if paddle4V == -1
     %         paddle4V = 0;
     %       end
     %     case 'd'
     %       if paddle4V == 1
     %         paddle4V = 0;
     %       end

         case 'rightarrow'
            if paddle2V == 1
              paddle2V = 0;
            end
          case 'leftarrow'
            if paddle2V == -1
              paddle2V = 0;
            end
          case 'uparrow'
            if paddle3V == 1
              paddle3V = 0;
            end
          case 'downarrow'
            if paddle3V == -1
              paddle3V = 0;
            end  

        end
      end

    %----------------------MAIN SCRIPT----------------------
    %for i = 4:5
    % seed_value = seed_value;

     createFigure;
     newGame;
     timer2 = 0;
     TrainingPoints = 0;
     paddleVelocity = [];

     value = [];
     layers_size = [9,12,3];
     epsilon_init = .2;
     
     Theta1_start = 1;
     Theta1_end = layers_size(2) * (layers_size(1) + 1);
     Theta2_start = Theta1_end + 1;
     % use 'end' for Theta2_end
     
    

     [initial_weight,initial_conditions_of_games] = initiate(seed_value,...
                    epsilon_init,layers_size);
     ballVector = initial_conditions_of_games{1};
     paddleV = initial_conditions_of_games{2};
     Params = [];
    % for i = 1:(size(initial_weight,2));
    %     Params = [Params;initial_weight{i}(:)];
    % end
    
    Params = TrainingParams;
    
    initial_weight{1} = reshape(TrainingParams(Theta1_start : Theta1_end), ...
                 layers_size(2), (layers_size(1) + 1));
             
    initial_weight{2} = reshape(TrainingParams(Theta2_start : end), ...
                 layers_size(3), (layers_size(2) + 1)); 

     paddle1V = paddleV(1);
     paddle2V = paddleV(2);
     paddle3V = paddleV(3);
     
     while ~quitGame  
      moveBall;
      X = [(ballX-75)/75,(ballY-75)/75,(ballSpeed-3.8)/2.2,...
                    ballVector(1),ballVector(2),(paddle_Pos(1)-75)/75,... 
                    (paddle_Pos(2)-75)/75,(paddle_Pos(3)-75)/75,...
                    (paddle_Pos(4)-75)/75];
      paddle4V = predict4P2(initial_weight, X) -2; 
      
     % paddleVelocity = [paddleVelocity; paddle4V]
        
      %value = [value; ballSpeed];
      movePaddles;
      refreshPlot;
       if timer2 == 55
          paddle1V = paddle1V*(-1);
          timer2 = timer2 + 1;
       elseif timer2 == 60
          paddle2V = paddle2V*(-1);
          timer2 = timer2 + 1;
       elseif timer2 == 65
          paddle3V = paddle3V*(-1);
          paddleVelocity = [paddleVelocity; paddle4V];
          timer2 = 0;
       else
          timer2 = timer2 + 1;
       end
      checkGoal;
     end
      close(fig);
      
      speed_score = TrainingPoints;
      checkValues = [-1,1];
      paddleScore = sum(ismember(checkValues,unique(paddleVelocity))); % checks to make sure the paddle moves both left and right  
      speed_scores = [speed_score,seed_value,paddleScore];
     % initial_weight{1}
   % end
   % save('speed_scores.mat', 'speed_scores')
end