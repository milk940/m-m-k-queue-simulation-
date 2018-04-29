function avg_response_time = sim_func(mode,arrival,service,m,setup_time,delayedoff_time,time_end)
% There are 7 user simulation parameters:
% 1. mode, which can either be random or trace.
% 2. arrival
% 3. service 
% 4. m, the number of servers. 
% 5. setup_time, the setup time for each server. Postive floating number.
% 6. delayedoff_time, the initial value of the count down timer (Tc) for each
% server. Postive floating number.
% 7. time_end, the simulation will stop when master clock exceed this
% parameter. Postive floating number.

%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Accounting parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%
response_time_cumulative = 0; %  The cumulative response time 
num_job_served = 0; % number of completed jobs at the end of the simulation

%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Events
%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% There are two events: An arrival event and a departure event
%
% An arrival event is specified by
% next_arrival_time = the time at which the next job arrives
% service_time_next_arrival = the service time of the next arrival
%
% A departure event is specified by
% next_departure_time = the time at which the next departure occurs
% arrival_time_next_departure = the time at which the next departing
% job arrives at the system
%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initialising the events
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% Initialising the arrival event based on mode
% When the simulation is in random mode

if strcmp(mode,'random')==1
    %
    %The inter-arrival probability distribution is exponentially
    %distributed with parameter arrival from the input.
    next_arrival_time = -log(1-rand(1))/arrival;
    %
    %The service time is the sum of three random numbers that are
    %exponentially distributed with parameter service from the input.
    service_time_next_arrival_1 = -log(1-rand(1))/service;
    service_time_next_arrival_2 = -log(1-rand(1))/service;
    service_time_next_arrival_3 = -log(1-rand(1))/service;
    service_time_next_arrival = service_time_next_arrival_1+service_time_next_arrival_2+service_time_next_arrival_3;
end

% 
% Initialise both departure events to empty
% Note: We use Inf (= infinity) to denote an empty departure event
% 
% both next_departure_time and arrival_time_next_departure are m-by-1 vectors 
next_departure_time = Inf * ones(m,1); 
arrival_time_next_departure = zeros(m,1);

% For checking
% events = [next_arrival_time service_time_next_arrival]; 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initialising the Master clock, server status, queue_length,
% queue_content
% 
% server_status m*3 matrix represents the status of servers. The first column shows the
% state of the server, where 0 is off, 1 is setup, 2 is busy and 3 is
% delayedoff, the second column shows the remaining setup time and the
% third column shows the remaining delayedoff time
% Initially all servers are off and both timers are 0
% 
% queue_length is the number of jobs in the queue
% 
% queue_content is a matrix with 3 columns that contains the information
% of job in queue. The first column contains the arrival time, the
% second column contains the service time and the third column show if the
% job is marked, where 1 means marked and 0 means unmakerd 
% The queue_content is to imitate a first-come first-serve queue 
% The 1st row has information on the 1st job in the queue etc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% Intialise the master clock 
master_clock = 0; 
% 
% Intialise server status
server_status = zeros(m,3);
% 
% Initialise queue
queue_content = [];
queue_length = 0;

% Start iteration until the end time
while (master_clock < time_end)
    % Find the server with the first departing job
    [first_departure_time,first_departure_server] = min(next_departure_time);
    % 
    % Find out whether the next event is an arrival or depature
    %
    % We use next_event_type = 1 for arrival and 0 for departure
    % 
    if (next_arrival_time < first_departure_time)
        next_event_time = next_arrival_time;
        next_event_type = 1;  
    else
        next_event_time = first_departure_time;
        % first departure server has already been found just now
        next_event_type = 0;
    end    
    
    %update master clock
    master_clock = next_event_time;
    %
    % take actions depending on the event type
    % 
    if (next_event_type == 1) % an arrival 
        if (any(server_status(:,1)==3)) % any server is delayedoff
            %
            % sent the job to server with the highest Tc and change the server's
            % status to busy
            [temp, chosen_server] = max(server_status(:,3));
            server_status(chosen_server,1) = 2;
            %
            % Schedule departure event with 
            % the departure time is arrival time + service time
            
            next_departure_time(chosen_server) = ...
            next_arrival_time + service_time_next_arrival;
            arrival_time_next_departure(chosen_server) = next_arrival_time;
       
        else
            if (any(server_status(:,1)==0)) % any server is off
                
            
%         if all(server_busy) 
%             % 
%             % add job to queue_content and
%             % increment queue length
%             % 
%             queue_content = [queue_content ; next_arrival_time service_time_next_arrival];
%             queue_length = queue_length + 1;        
%         else % not all server are busy
%             % 
%             % Send the job to any available server
%             % 
%             % Schedule departure event with 
%             % the departure time is arrival time + service time 
%             % Also, set server_busy to 1
%             % 
%             idle_server = min(find(server_busy == 0));
%             next_departure_time(idle_server) = ...
%                 next_arrival_time + service_time_next_arrival;
%             arrival_time_next_departure(idle_server) = next_arrival_time;
%             server_busy(idle_server) = 1;
%         end
        % generate a new job and schedule its arrival 
        next_arrival_time = master_clock - log(1-rand(1))/lambda;
        service_time_next_arrival = -log(1-rand(1))/mu; 
        
        % This is for checking only
        % events = [events ; next_arrival_time service_time_next_arrival]; 
    else % a departure 
        % 
        % Update the variables:
        % 1) Cumulative response time T
        % 2) Number of departed jobs N
        % 
        response_time_cumulative = response_time_cumulative + master_clock - arrival_time_next_departure(first_departure_server);
        num_job_served = num_job_served + 1;
        % 
        if queue_length % queue not empty
            % 
            % schedule the next departure event using the first job 
            % in the queue, i.e. use the 1st row in queue_content
            % 
            next_departure_time(first_departure_server) = ...
                master_clock + queue_content(1,2);
            arrival_time_next_departure(first_departure_server) = ...
                queue_content(1,1);
            % 
            % remove job from queue and decrement queue length
            % 
            queue_content(1,:) = [];
            queue_length = queue_length - 1;
        else % queue empty
            next_departure_time(first_departure_server) = Inf;
            server_busy(first_departure_server) = 0;
        end    
    end        
end        
     
avg_response_time = response_time_cumulative/num_job_served;

    