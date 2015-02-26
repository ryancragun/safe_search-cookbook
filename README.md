# safe-search-cookbook

A library cookbook to extend the Chef DSL to include a `safe_search` function.
The function is backwards compatible with the standard `search`, however, it
keeps a local cache of all searches.  This functionality is particularly useful
in the case of moving nodes to a new Chef Cluster.  When the node is moved it's
unlikely that the search index on the new cluster has been completely warmed,
thus any searches the node makes will likely be invalid.  With `safe_search`
the client can choose to use the old cached results, current results, or a merged
set of the current and cached results.

By default `safe_search` will query the Chef Server and compare the results with
the cached results from the previous run.  If the current result set is >= 90%
of the cached set then it will use the new results, otherwise it will return
the cached set. You can dynamically configure a different threshold by
providing the threshold option in the search, e.g:

```ruby
safe_search(:node, 'role:hadoop', threshold: 80)
```

You can also opt to merge results:

```ruby
safe_search(:node, 'role:cassandra', merge: true)
```

When the merge function is enabled the threshold will be ignored and both results
will be merged every time.

## Supported Platforms

The recipe DSL extension is available to all Chef Clients on versions 12.1.0 or
greater.  The cookbook will still compile on lower client versions but the DSL
will not be extended because of compatibility issues.

## Usage

### safe-search::default

Include `safe-search` in your node's `run_list`:

```json
{
  "run_list": [
    "recipe[safe-search::default]"
  ]
}
```

Then start `safe_search`ing in your recipes!

## License and Authors

Author:: Ryan Cragun (<ryan@chef.io>)
