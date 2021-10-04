FROM ruby:2.6.3
RUN apt-get update -qq && apt-get install -y nodejs postgresql-client
RUN mkdir /Sport_simulator
WORKDIR /Sport_simulator
COPY Gemfile /Sport_simulator/Gemfile
COPY Gemfile.lock /Sport_simulator/Gemfile.lock
RUN bundle install
COPY . /Sport_simulator

# Add a script to be executed every time the container starts.
COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]
EXPOSE 3000

# Start the main process.
CMD ["rails", "server", "-b", "0.0.0.0"]