function avg_response_time = sim_func(mode,arrival,service,m,setup_time,delayedoff_time,time_end)
%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Input parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
% There are four events: An arrival event, a departure event, a server
% setup complete event and a server delayedoff complete event
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

if strcmp(mode,'random')==1 % When the simulation is in random mode
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
% Initialising the Master clock, server status, queue_length and
% queue_content
% 
% server_status is a m*3 matrix represents the status of servers. The first column shows the
% state of the server, where 0 is off, 1 is setup, 2 is busy and 3 is
% delayedoff, the second column shows the setup complete time and the
% third column shows the delayedoff (Tc) complete time
% Initially all servers are off and both times are NaN
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
server_status = repmat([0,nan,nan],m,1);
% 
% Initialise queue
queue_content = [];
queue_length = 0;

% Start iteration until the end time
while (master_clock < time_end)
    %%%%%%%%%%%%%%%%%%%%%%%[
    %Determining next event type
    %%%%%%%%%%%%%%%%%%%%%%%
    % Find the server with the first departing job
    [first_departure_time,first_departure_server] = min(next_departure_time);
    % Find the server that will first complete setup state 
    [first_setup_time,first_setup_server] = min(server_status(:,2));
    % Find the server that will first complete delayedoff state
    [first_delayedoff_time,first_delayedoff_server] = min(server_status(:,3));
    %
    % Find out whether the next event is an arrival, depature, completing
    % setup or completing delayedoff
    % We use next_event_type = 0 for departure, 1 for arrival, 2 for
    % completing setup and 3 for completing delayedoff
    % The type of the event is determined by time, which are next arrival
    % time, first departure time, first setup time and first delayedoff time. 
    % The event with the minimum time will be the next event.
    %
    time_list=[next_arrival_time, first_departure_time, first_setup_time, first_delayedoff_time];
    if (min(time_list)==next_arrival_time) %arrival event
        next_event_type = 1;
        next_event_time = next_arrival_time;
    elseif (min(time_list)==first_departure_time) %departure event
        next_event_type = 0;
        next_event_time = first_departure_time;
    elseif (min(time_list)==first_setup_time) %completing setup event
        next_event_type = 2;
        next_event_time = first_setup_time;
    else %completing delayed off event 
        next_event_tyoe =3;
        next_event_time = first_delayedoff_time;
    end    
       
    %update master clock
    master_clock = next_event_time;
    %
    % take actions depending on the event type
    % 
    if (next_event_type == 1) % an arrival event  
        if (any(server_status(:,1)==3)) % any server is delayedoff
            %
            % send the job to server with the highest remaining Tc and change the server's
            % status to busy
            [temp, chosen_server] = max(server_status(:,3));
            server_status(chosen_server,:) = [2,nan,nan];
            %
            % Schedule departure event with 
            % the departure time is arrival time + service time
            next_departure_time(chosen_server) = ...
            next_arrival_time + service_time_next_arrival;
            arrival_time_next_departure(chosen_server) = next_arrival_time;
       
        else
            if (any(server_status(:,1)==0)) % any server is off
                %
                % choose a random server and change the server's status to
                % setup 
                temp_list = find(any(server_status(:,1)==0)); %all servers in off state
                pos = randi(length(temp_list));
                chosen_server = temp_list(pos);
                server_status(chosen_server,1)=3; %change server state to setup
                %
                % add setup complete time to the server status
                server_status(chosen_server,2)=master_clock+setup_time;
                %
                % Increment the length of queue by 1
                queue_length = queue_length+1;
                %
                % store the arriving job in queue including its arrival
                % time and service time; mark the job
                job_arrive_info = [next_arrival_time, service_time_next_arrival, 1];
                queue_content = [queue_content;job_arrive_info];
            else % all servers are either busy or setup
                %
                % store the job in queue and unmark the job
                queue_length = queue_length+1;
                job_arrive_info = [next_arrival_time, service_time_next_arrival, 0];
                queue_content = [queue_content;job_arrive_info];
            end
        end
        % generate a new job and schedule its arrival
        next_arrival_time = master_clock - log(1-rand(1))/arrival;
        service_time_next_arrival = -log(1-rand(1))/service; 
     
    elseif (next_event_type == 0) % a departure event
        % 
        % Update the variables:
        % 1) Cumulative response time T
        % 2) Number of departed customers N
        % 
        response_time_cumulative = response_time_cumulative + master_clock - arrival_time_next_departure(first_departure_server);
        num_job_served = num_job_served + 1;
        
        if (queue_length==0) %queue is empty
            %
            % server becomes delayedoff and set up the delayedoff timer
            server_status(first_departure_server,1) = 3;
            server_status(first_departure_server,3) = master_clock+delayedoff_time;
            % empty this departure event
            next_departure_time(first_departure_server) = Inf;
            arrival_time_next_departure(first_departure_server) = 0;
            
        else %queue is not empty
            %
            % the server remains busy and takes in the first job in queue
            job_send_info = queue_content(1,:); % information of the frist job in queue 
            next_departure_time(first_departure_server) = job_send_info(2)+master_clock;
            arrival_time_next_departure(first_departure_server) = job_send_info(1);
            %
            % remove the sent job from queue and decrement number of jobs in queue by 1
            queue_content = queue_content(2:end);
            queue_length = queue_length-1;
            
            if (job_send_info(3)==1) % if the sent job is marked
                if(any(queue_content(:,3)==0)) % if any remaining job in queue is unmarked
                    %
                    % change the first umarked job in queue to marked
                    row_number = find(queue_content(:,3)==0,1);
                    queue_content(row_number,3)=1;
                else %if no remaining job in queue is unmarked
                    %
                    % turn off the server in set-up with the longest
                    % remaining set up time
                    [temp, chosen_server] = max(server_status(:,2));
                    server_status(chosen_server,:) = [0,nan,nan];
                end
            end
        end
    
    
    elseif (next_event_type == 2) %completing setup event
        %
        % A server finishes setup. 
        % Find the first marked job in queue
        row_number = find(queue_content(:,3)==1,1);
        job_send_info =  queue_content(1,:);
        % remove this job from queue
        queue_length = queue_length-1;
        removerows(queue_content,row_number);
        % sent this job to this server
        next_departure_time(first_setup_server) = job_send_info(2)+master_clock;
        arrival_time_next_departure(first_setup_server) = job_send_info(1);
        % change server status to busy
        server_status(first_setup_server,:)=[2,nan,nan];
        
    else %completing delayedoff event
        %
        % A server finishes delayedoff
        % Change the server to OFF
        server_status(first_delayedoff_server,:)=[0,nan,nan];
    end
        
                    
                    
                
                 
                    
                

            
            
            
            
       
end        
     
avg_response_time = response_time_cumulative/num_job_served;

    