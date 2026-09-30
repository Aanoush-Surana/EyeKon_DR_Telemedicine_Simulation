%% DR Telemedicine Simulation Parameters

%% Simulation
SIMULATION_TIME_HOURS = 8;
SIMULATION_TIME = SIMULATION_TIME_HOURS * 60;   % minutes

%% Patient Arrival
PATIENTS_PER_HOUR = 15;

% Average time between patient arrivals
INTERARRIVAL_TIME = 60 / PATIENTS_PER_HOUR;

%% Registration
REGISTRATION_TIME = 1.5;        % minutes
REGISTRATION_SERVERS = 1;

%% Fundus Camera
NUM_CAMERAS = 1;
CAPTURE_TIME = 3;               % minutes

%% Image Quality Assessment
POOR_IMAGE_RATE = 0.15;
MAX_RECAPTURE_ATTEMPTS = 2;

%% AI Processing
% Temporary value.
% Replace with measured MATLAB processing time later.
AI_PROCESSING_TIME = 20/60;     % minutes

%% DR Classification
% Simulation assumption only.
REFERABLE_RATE = 0.15;

% Grade >= 2 is referable
REFERABLE_THRESHOLD = 2;

%% Network
IMAGE_SIZE_MB = 6;
UPLOAD_BANDWIDTH_MBPS = 2;

SERVER_PROCESSING_TIME = 5/60;  % minutes

%% Doctor
NUM_DOCTORS = 1;
DOCTOR_REVIEW_TIME = 2;         % minutes

%% Program-level target
ANNUAL_PATIENT_TARGET = 100000;
WORKING_DAYS_PER_YEAR = 250;