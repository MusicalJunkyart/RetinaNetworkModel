function plotOrientation(thisModel)
%PLOTORIENTATION Summary of this function goes here

    weightMatrix = thisModel.weightMatrix;
    nReferences = size(weightMatrix, 1);
    nRows = ceil(sqrt(nReferences));
    nColumns = ceil(sqrt(nReferences));
    
    fig = figure('Name', 'Reference Neuron Ensemble');
    for referenceIndex = 1 : nReferences
        subplot(nColumns, nRows, referenceIndex);
       
        detectorCoordinates = thisModel.detectorCoordinates;
        isConnected = (weightMatrix(referenceIndex, :) > 0)';

        x1 = detectorCoordinates(1, ~isConnected);
        y1 = detectorCoordinates(2, ~isConnected);
        x2 = detectorCoordinates(1, isConnected);
        y2 = detectorCoordinates(2, isConnected);
        w2 = weightMatrix(referenceIndex, isConnected)';

        hold on
        markerSize1 = 20;
        markerSize2 = 50;
        markerType1 = '.';
        markerType2 = '.';
        markerColor1 = [192, 39, 57] / 255;
        markerColor2 = [41, 199, 172] / 255;
        gradientColor2 = markerColor2 .* interpolate(0.5, 1, w2);
        lineColor = [210, 240, 210] / 255;
        backgroundColor = [35, 41, 49] / 255;

        scatter(x1, y1, markerSize1, markerColor1, markerType1);
        scatter(x2, y2, markerSize2, gradientColor2, markerType2);

        % Plot the input line 
        [thetaRadians, R2] = regressionTLS(x2, y2, w2);
        endPointsX = [cos(thetaRadians), -cos(thetaRadians)]';
        endPointsY = [sin(thetaRadians), -sin(thetaRadians)]';
        plot(endPointsX, endPointsY, '-', ...
                                     'Color', lineColor, ...
                                     'LineWidth', 1.2);
        set(0,'DefaultAxesTitleFontWeight', 'normal');
        labelX = sprintf('� = %.1f�', 180/pi * thetaRadians);
        labelY = sprintf('R� = %.3f', R2);
        %labelTitle = sprintf('index %u', referenceIndex);
        %title(labelTitle)
        xlabel(labelX) 
        ylabel(labelY)
                
        % Specify common title, X and Y labels
        set(gca,'Color', backgroundColor);
        set(gca,'XTick',[], 'YTick', []);
        ax = axes(fig, 'visible', 'off'); 
        ax.Title.Visible = 'on';
        ax.XLabel.Visible = 'on';
        ax.YLabel.Visible = 'on';
        ylabel(ax, 'Pearson Sample Correlation Coefficient ');
        xlabel(ax, 'Angle Estimation TLS');
        title(ax, 'Reference Neurons Orientation Preference');
        hold off

    end
end

function [theta, R2, rho] = regressionTLS(X, Y, W)
%REGRESSIONMSE Computes the line that best fits the wighted data
 % We have a line with orientation the unit vector u. The orthogonal
 % distance from the point i to the line is
 % di^2 = |pi|^2 + dot(u, pi)^2 for index i and |u| = 1
 % MSE = sum(di^2) 
 %     = trace(PP') + u'(PP')u  where PP' = sum(pi pi')
 % dMSE/d� = -2u'(PP')du/d�
 % �n+1 = �n - � dMSE/d� = 
 %        �n + 2� u'(PP')du/d� 
 
    P = (W(:) .* [X(:), Y(:)])';
    u = @(theta) [cos(theta), sin(theta)]';
    v = @(theta) [-sin(theta), cos(theta)]';
    grad = @(theta) -u(theta)' * (P * P') * v(theta);

    nIterations = 40;
    threshold = 1e-4;
    theta = zeros(nIterations, 1);
    theta(2) = pi / nIterations;

    for n = 2 : nIterations - 1
        step = abs((theta(n) - theta(n-1)) / (grad(theta(n)) - grad(theta(n-1))));
        theta(n+1) = mod(theta(n) - step * grad(theta(n)), pi);            
        if abs(theta(n+1) - theta(n)) < threshold
            break
        end
    end
    theta = theta(n+1);

    % Modified coefficient of determination
    distSquared = vecnorm(P).^2 - (u(theta)' * P).^2;
    SSres = sum(distSquared);
    SStot = sum(vecnorm(P - mean(P,2)).^2);
    R2 = 1 - SSres/SStot;
    
    % Pearson sample correlation coefficient 
    x = (P(1,:) - mean(P(1,:)));
    y = (P(2,:) - mean(P(2,:)));
    rho = sum(x .* y) / sqrt(sum(x.^2) * sum(y.^2));
    
end

function P = interpolate(A, B, t)
    P = t * B + (1 - t) * A;
end



