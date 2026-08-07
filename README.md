# InvenioRDM Demo Site

Available at <https://inveniordm.web.cern.ch>.

Further documentation on InvenioRDM available at <http://inveniordm.docs.cern.ch>.

## Development

To setup the instance locally:

```shell
uv tool install invenio-cli
invenio-cli check-requirements --development
invenio-cli install
invenio-cli services setup
invenio-cli run
```

Python dependencies are managed with [uv](https://docs.astral.sh/uv/) and
JavaScript ones with [pnpm](https://pnpm.io/). Assets are bundled with
[Rspack](https://rspack.dev/).

See the [InvenioRDM Documentation](https://inveniordm.docs.cern.ch/install/) for further installation options.

### Update dependencies

`uv.lock` is resolved for all platforms, so it can be regenerated anywhere:

```shell
invenio-cli packages lock
```
