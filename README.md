# safe-search-cookbook

TODO: Enter the cookbook description here.

## Supported Platforms

TODO: List your supported platforms.

## Attributes

<table>
  <tr>
    <th>Key</th>
    <th>Type</th>
    <th>Description</th>
    <th>Default</th>
  </tr>
  <tr>
    <td><tt>['safe-search']['bacon']</tt></td>
    <td>Boolean</td>
    <td>whether to include bacon</td>
    <td><tt>true</tt></td>
  </tr>
</table>

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

## License and Authors

Author:: Ryan Cragun (<ryan@chef.io>)
