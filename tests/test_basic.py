from comfy_explore import list_samples


def test_list_samples_returns_list_for_existing_dir():
    samples = list_samples("samples")
    assert isinstance(samples, list)

