import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

class SearchScreen extends StatelessWidget {
  SearchScreen({Key? key}) : super(key: key);

  final link = HttpLink('https://api.spacex.land/graphql/');

  @override
  Widget build(BuildContext context) {
    final client = ValueNotifier<GraphQLClient>(
      GraphQLClient(
        cache: GraphQLCache(),
        link: link,
      ),
    );

    return GraphQLProvider(
      client: client,
      child: const CacheProvider(
        child: _SearchScreen(),
      ),
    );
  }
}

const getMissionByName = r'''
  query GetMissionsByName($name: String!, $limit: Int!, $offset: Int!) {
    launches(find: {mission_name: $name}, limit: $limit, offset: $offset) {
      mission_name
      details
    }
  }''';

class _SearchScreen extends StatefulWidget {
  const _SearchScreen({Key? key}) : super(key: key);
  @override
  __SearchScreenState createState() => __SearchScreenState();
}

class __SearchScreenState extends State<_SearchScreen> {
  var query = "";
  var limit = 10;
  var offset = 0;

  QueryOptions get options {
    return QueryOptions(
      document: gql(getMissionByName),
      variables: {
        "name": query,
        "limit": limit,
        "offset": offset,
      },
    );
  }

  void changeQuery(String name) {
    if (name.length < 3 && name.isNotEmpty) {
      return;
    }

    setState(() {
      query = name;
      limit = 10;
      offset = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("SpaceX Missins"),
      ),
      body: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Filter mission',
              ),
              keyboardType: TextInputType.text,
              onChanged: changeQuery,
            ),
          ),
          Query(
            options: options,
            builder: (
              QueryResult result, {
              Future<QueryResult> Function(FetchMoreOptions)? fetchMore,
              Future<QueryResult?> Function()? refetch,
            }) {
              if (result.hasException) {
                return Text(result.exception.toString());
              }

              if (result.data == null) {
                return Expanded(
                  child: Center(
                    child: _Indicator(),
                  ),
                );
              }

              final missions = (result.data!['launches'] as List<dynamic>);

              return Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.only(
                    top: 8,
                    left: 12,
                    right: 12,
                  ),
                  itemCount: missions.length + 1,
                  itemBuilder: (_, index) {
                    if (index >= missions.length) {
                      offset += limit;

                      fetchMore?.call(
                        FetchMoreOptions(
                          variables: {...options.variables, "offset": offset},
                          updateQuery: (previousResult, newResult) {
                            previousResult!["launches"].addAll(
                              newResult!["launches"],
                            );

                            return previousResult;
                          },
                        ),
                      );

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: _Indicator(),
                        ),
                      );
                    }

                    var node = missions[index];

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            node["mission_name"],
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(node["details"] ?? "# no information")
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Indicator extends StatelessWidget {
  const _Indicator({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      width: 24,
      child: CircularProgressIndicator(
        strokeWidth: 1,
      ),
    );
  }
}

QueryBuilder withGenericHandling(QueryBuilder builder) {
  return (result, {fetchMore, refetch}) {
    if (result.hasException) {
      return Text(result.exception.toString());
    }

    return builder(result, fetchMore: fetchMore, refetch: refetch);
  };
}
