require 'spec_helper'
require 'active_record/connection_adapters/read_only_adapter'

describe "Test connection adapters" do
  if MariaDbClusterPool::TestModel.database_configs.empty?
    puts "No adapters specified for testing. Specify the adapters with TEST_ADAPTERS variable"
  else
    MariaDbClusterPool::TestModel.database_configs.keys.each do |adapter|
      context adapter do
        let(:model){ MariaDbClusterPool::TestModel.db_model(adapter) }
        let(:connection){ model.connection }
        let(:master_connection){ connection.master_connection }
  
        before(:all) do
          if ActiveRecord::VERSION::MAJOR < 3 || (ActiveRecord::VERSION::MAJOR == 4 && ActiveRecord::VERSION::MINOR == 0)
            ActiveRecord::Base.configurations = {'adapter' => "sqlite3", 'database' => ":memory:"}
          else
            ActiveRecord::Base.configurations = {"test" => {'adapter' => "sqlite3", 'database' => ":memory:"}}
          end
          ActiveRecord::Base.establish_connection('adapter' => "sqlite3", 'database' => ":memory:")
          ActiveRecord::Base.connection
          MariaDbClusterPool::TestModel.db_model(adapter).create_tables
        end
  
        after(:all) do
          MariaDbClusterPool::TestModel.db_model(adapter).drop_tables
          MariaDbClusterPool::TestModel.db_model(adapter).cleanup_database!
        end
  
        before(:each) do
          model.create!(:name => 'test', :value => 1)
        end

        after(:each) do
          model.delete_all
        end
      
        it "should quote table names properly" do
          connection.quote_table_name("foo").should == master_connection.quote_table_name("foo")
        end

        it "should quote column names properly" do
          connection.quote_column_name("foo").should == master_connection.quote_column_name("foo")
        end

        it "should quote string properly" do
          connection.quote_string("foo").should == master_connection.quote_string("foo")
        end

        it "should quote booleans properly" do
          connection.quoted_true.should == master_connection.quoted_true
          connection.quoted_false.should == master_connection.quoted_false
        end

        it "should quote dates properly" do
          date = Date.today
          time = Time.now
          connection.quoted_date(date).should == master_connection.quoted_date(date)
          connection.quoted_date(time).should == master_connection.quoted_date(time)
        end

        it "should query for records" do
          record = model.find_by_name("test")
          record.name.should == "test"
        end

        it "should work with query caching" do
          record_id =  model.first.id
          model.cache do
            found = model.find(record_id)
            found.name = "new value"
            found.save!
            model.find(record_id).name.should == "new value"
          end
        end

        context "master connection" do
          let(:insert_sql){ "INSERT INTO #{connection.quote_table_name(model.table_name)} (#{connection.quote_column_name('name')}) VALUES ('new')" }
          let(:update_sql){ "UPDATE #{connection.quote_table_name(model.table_name)} SET #{connection.quote_column_name('value')} = 2" }
          let(:delete_sql){ "DELETE FROM #{connection.quote_table_name(model.table_name)}" }

          it "should send update to the master connection" do
            connection.update(update_sql)
            model.first.value.should == 2
          end

          it "should send insert to the master connection" do
            connection.update(insert_sql)
            model.find_by_name("new").should_not == nil
          end

          it "should send delete to the master connection" do
            connection.update(delete_sql)
            model.first.should == nil
          end

          it "should send transaction to the master connection" do
            connection.transaction do
              connection.update(update_sql)
            end
            model.first.value.should == 2
          end

          it "should send schema altering statements to the master connection" do
            begin
              connection.create_table(:foo) do |t|
                t.string :name
              end
              connection.add_index(:foo, :name)
            ensure
              connection.remove_index(:foo, :name)
              connection.drop_table(:foo)
            end
          end

          it "should properly dump the schema" do
            schema = <<-EOS
              ActiveRecord::Schema.define(version: 0) do
                create_table "#{model.table_name}", force: :cascade do |t|
                  t.string  "name", limit: 255
                  t.integer "value", limit: 4
                end
              end
            EOS
            schema = schema.gsub(/^ +/, '').gsub(/ +/, ' ').strip

            io = StringIO.new
            ActiveRecord::SchemaDumper.dump(connection, io)
            generated_schema = io.string.gsub(/^#.*$/, '').gsub(/\n+/, "\n").gsub(/^ +/, '').gsub(/ +/, ' ').strip
            generated_schema.should == schema
          end
        end
      end
    end
  end
end
