from .core_widget import BaseWidget
from .core_view_dataframe import ViewDataFrame


def view_dataframe(
    columns=None, width=400, height=400, force_computation=False
):
    """

    Parameters
    ----------

    columns: list, default None
        display subset of columns, and all columns if None

    width: int,  default 400

    height: int,  default 400

    force_computation: bool, default False
        if cuxfilter.DataFrame.data is of type dask_cudf:
        - force_computation=False returns df.head(1000)
        - force_computation=True returns entire df, but it can be
        computationally intensive

    Returns
    -------
    A view dataframe object.
    Type cuxfilter.charts.core_view_dataframe.ViewDataFrame
    """
    plot = ViewDataFrame(columns, width, height, force_computation)
    plot.chart_type = "view_dataframe"
    return plot
