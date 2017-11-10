RSpec.describe Opentsdb::Client do
  let(:client) { Opentsdb::Client.new }

  describe '#drop_caches' do
    it 'dropped caches' do
     response = client.drop_caches
      expect(response['status']).to eq('200')
    end
  end

  describe '#assign_uid' do
    context 'when uid name is fresh' do
      it 'assigns metrics uid' do
        response = client.assign_uid({metric: ['test.somemetric']})
        expect(response).to have_key('metric')
        expect(response['metric']).to have_key('test.somemetric')
      end

      it 'assigns tagk uid' do
        response = client.assign_uid({tagk: ['test.tagk']})
        expect(response).to have_key('tagk')
        expect(response['tagk']).to have_key('test.tagk')
      end

      it 'assigns tagv uid' do
        response = client.assign_uid({tagv: ['test.tagv']})
        expect(response).to have_key('tagv')
        expect(response['tagv']).to have_key('test.tagv')
      end
    end

    context 'when uid name was previously used' do
      it 'returns an error' do
        response = client.assign_uid({metric: ['test.duplicate']})
        response = client.assign_uid({metric: ['test.duplicate']})

        expect(response).to have_key('metric_errors')
        expect(response['metric_errors']).to have_key('test.duplicate')
      end
    end

  end

  describe '#put' do
    let!(:entry) do
      {
        metric: 'test.metric',
        timestamp: DateTime.now.to_i,
        value: rand(10_000_000),
        tags: {
          'test.host': 'test.someotherhost'
        }
      }
    end

    context 'when metric uid exists' do
      it 'saves single data entry' do
        response = client.put(entry)

        expect(response).to have_key('success')
        expect(response['success']).to eq(1)
      end

      it 'saves multiple entries' do
        entry_one = entry
        entry_two = entry.dup.merge(timestamp: DateTime.now.to_i+1)

        response = client.put([entry_one, entry_two])

        expect(response).to have_key('success')
        expect(response['success']).to eq(2)
      end
    end

    context 'when metric uid do not exist' do
      it 'fails to save entry' do
        wrong_entry = entry.dup.merge(metric: 'test.nonexistent')
        response = client.put(wrong_entry)

        expect(response).to have_key('failed')
        expect(response['failed']).to eq(1)
      end
    end
  end

  describe '#query' do
    let!(:query) do
      {
        start: 1507291372,
        end: 1507292814,
        queries: [
          {
            aggregator: 'sum',
            metric: 'test.metric',
            rate: false,
            tags: {
              'test.host': '*'
            }
          }
        ]
      }
    end

    context 'when metrics exists' do
      context 'and querying existing data' do
        it 'returns data points' do
          result = client.query(query).first

          expect(result).not_to be_nil
          expect(result['metric']).to eq('test.metric')
          expect(result['tags']).to have_key('test.host')
        end
      end

      context 'and querying not existing data' do
        it 'returns empty result' do
          local_query = query.dup
          local_query[:start] = 1407291372
          local_query[:end] = 1407292814
          result = client.query(local_query)

          expect(result).to be_empty
        end
      end
    end

    context 'when metrics does not exist' do
      it 'raise error' do
        wrong_query = query.dup
        wrong_query[:queries].first[:metric] = 'test.bad_metric'
        expect { client.query(wrong_query) }.to raise_error(Opentsdb::ApiError)
      end
    end
  end

  describe '#exp' do
    let!(:query) do
      {
        time: {
          start: '1y-ago',
          aggregator: 'sum'
        },
        filters: [
          {
            tags: [
              {
                type: 'wildcard',
                tagk: 'test.host',
                filter: 'myhost*',
                groupBy: true
              }
            ],
            id: 'f1'
          }
        ],
        metrics: [
          {
            id: 'a',
            metric: 'test.metric',
            filter: 'f1',
            fillPolicy: {
              policy: 'nan'
            }
          },
          {
            id: 'b',
            metric: 'test.othermetric',
            filter: 'f1',
            fillPolicy: {
              policy: 'nan'
            }
          }
         ],
         expressions: [
             {
                 id: 'e',
                 expr: 'a + b'
             }
          ],
          outputs: [
            {
              id: 'e',
              alias: 'Mega expression'
            },
            {
              id: 'a',
              alias: 'CPU User'
            }
          ]
       }
    end

    it 'returns results' do
      results = client.exp(query)

      expect(results).not_to be_nil
      expect(results).to be_kind_of(Hash)
      expect(results["outputs"]).to be_kind_of(Array)
      expect(results["outputs"].first["dps"]).not_to be_empty
    end
  end

  describe '#last' do
    let!(:query) do
      current_date = DateTime.now
      start_date = DateTime.parse('2017-01-01 00:00:00')
      hours = (current_date - start_date).to_i * 24

      {
        queries: [
          {
            metric: 'test.metric',
            tags: {
              'test.host': 'myhost'
            }
          }
        ],
        resolveNames: true,
        backScan: hours
      }
    end

    it 'returns last data point' do
      result = client.last(query).first

      expect(result).not_to be_nil
      expect(result['timestamp']).to eq(1507292814000)
      expect(result['value']).to eq('100')
    end

    it 'returns empty result' do
      new_query = query.dup
      new_query[:backScan] = 1
      result = client.last(new_query)

      expect(result).to be_empty
    end
  end

  describe '#suggest' do
    it 'returns metric' do
      suggestions = client.suggest('test', 'metrics')

      expect(suggestions).to include('test.metric')
    end

    it 'returns empty result' do
      suggestions = client.suggest('nonexistent', 'metrics')

      expect(suggestions).not_to include('test.metric')
    end
  end
end
