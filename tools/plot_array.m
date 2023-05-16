clear all;    % remove all Variables from the Workspace
clc;          % Clear the command window

% Base Parameters for the calculation
% The Frequency as such does not really matter - the
% crucial part is the antenna distance in relation to
% the Wavelength (l/2 or l/4 or the like)
% If we set the frequency to be equal to c, then lambda is 1

Frequency = 3e8;
c = 3e8;                    % Light speed / Wave speed in vacuum
WaveLength = c/Frequency;   % Wave length (Lambda)
T = 1/Frequency;            % Time period for one entire wave
d = WaveLength/2;           % Distance of the Antennas / Array Elements
WaveNumber = 2*pi/WaveLength;

% Here we define the number of samples / iterations and the resolution
% or rather discretion of the samples. You can increase the number to
% get a better ("rounder") plot or decrease to plot faster.
% We actually use this value for the plot resolution and for the plot loop

Ntheta = 120;                    % Number of angular samples
theta = 0:2*pi/Ntheta:(2*pi);    % the Array from 0 to 360° in Radians (2pi)

% The number of beams to show (6 or 8 gives a good graph)
% The more beams, the smaller they will show.

beams=8
beamRadius=beams/4
r = -beamRadius*d:d:beamRadius*d;

for phaseShift = 1:length(theta) % Sweep through angles
    delta = theta(phaseShift);

    A = ones(length(r));
    Fa = zeros(1,length(theta));

    for i = 1:length(r)
        temp = A(i) * exp(-1i*(i-beams)*delta + 1i*WaveNumber*(i-beams)*d*cos(theta));
        Fa = Fa + temp;
    end
    Fa = abs(Fa);

    % Now lets plot
    
    clf; 
    set(gcf,'Color',[1 1 1]); 
    polar(theta, -Fa/max(Fa)); 
    
    
    titleText = sprintf('Phased Array\n(Antenna Distance %d Lambda)\n(Phase Shift: %d degrees)', d*WaveLength,delta*360/(2*pi));
    title(titleText, 'FontSize', 18, 'FontWeight', 'bold', 'Position', [0.1, 1.5, 0])

    % let it draw and refresh (in Editor mode)
    pause(0.001);
end %phaseShift
